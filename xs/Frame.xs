#include "webkit-perl.h"
#include <JavaScriptCore/JavaScript.h>


static const char*
get_type (JSGlobalContextRef context, JSValueRef value) {

    switch (JSValueGetType(context, value)) {
        case kJSTypeUndefined:
            return "undefined";
        case kJSTypeNull:
            return "null";
        case kJSTypeBoolean:
            return "boolean";
        case kJSTypeNumber:
            return "number";
        case kJSTypeString:
            return "string";
        case kJSTypeObject:
            return "object";
        default:
            return "????";
    }
}


static gchar*
js_to_str (JSStringRef js_str) {
    gint size;
    gchar* str;

    if (js_str == NULL) return NULL;

    size = JSStringGetMaximumUTF8CStringSize(js_str);
    str = g_malloc(size);
    JSStringGetUTF8CString(js_str, str, size);
    return str;
}


static gchar*
js_to_json (JSGlobalContextRef context, JSValueRef value) {
    JSStringRef js_value;
    gchar *str;

    js_value = JSValueCreateJSONString(context, value, 0, NULL);
    if (js_value == NULL) {
        return NULL;
    }
    str = js_to_str(js_value);
    JSStringRelease(js_value);

    return str;
}


static SV*
js_to_sv (JSGlobalContextRef context, JSValueRef value, GHashTable *g_hash, gboolean use_globals) {

    if (value == NULL) {
        return use_globals ? &PL_sv_undef : newSV(0);
    }

    switch (JSValueGetType(context, value)) {
        case kJSTypeUndefined:
        case kJSTypeNull:
            return use_globals ? &PL_sv_undef : newSV(0);

        case kJSTypeBoolean:
        {
            gboolean val = JSValueToBoolean(context, value);
            if (use_globals) {
                return val ? &PL_sv_yes : &PL_sv_no;
            }
            return val ? newSViv(1) : newSV(0);
        }

        case kJSTypeNumber:
            return newSVnv(JSValueToNumber(context, value, NULL));

        case kJSTypeString:
        {
            JSStringRef js_value;
            gchar *str_value;
            SV *val;

            js_value = JSValueToStringCopy(context, value, NULL);
            if (js_value == NULL) {
                return use_globals ? &PL_sv_undef : newSV(0);
            }


            str_value = js_to_str(js_value);
            JSStringRelease(js_value);
            val = newSVpv(str_value, 0);
            g_free(str_value);
            return val;
        }

        case kJSTypeObject:
        {
            JSPropertyNameArrayRef properties = NULL;
            JSObjectRef object;
            size_t count, i;
            JSValueRef js_prototype;
            gchar *prototype;
            gboolean is_array;
            AV *av;
            HV *hv;
            SV *sv;

            /* Handle circular references by returning the SV that matches the
               JS object.
             */
            sv = g_hash_table_lookup(g_hash, value);
            if (sv != NULL) {
                return sv;
            }

            object = JSValueToObject(context, value, NULL);
            properties = JSObjectCopyPropertyNames(context, object);

            js_prototype = JSObjectGetPrototype(context, object);
            prototype = js_to_json(context, js_prototype);
            if (strcmp(prototype, "[]") == 0) {
                is_array = TRUE;
                av = newAV();
            }
            else {
                is_array = FALSE;
                hv = newHV();
            }
            g_free(prototype);


            count = JSPropertyNameArrayGetCount(properties);
            for (i = 0; i < count; ++i) {
                JSStringRef js_name;
                JSValueRef js_value;
                gchar *name, *value;
                SV *sv;

                js_name = JSPropertyNameArrayGetNameAtIndex(properties, i);
                js_value = JSObjectGetProperty(context, object, js_name, NULL);

                if (JSValueIsObject(context, js_value)) {
                    JSObjectRef js_object = JSValueToObject(context, js_value, NULL);
                     if (JSObjectIsFunction(context, js_object) || JSObjectIsConstructor(context, js_object)) {
                        continue;
                    }
                }


                name = js_to_str(js_name);
                value = js_to_json(context, js_value);
                printf("[%2d] Property: %s => %s\n", i, name, value);
                fflush(stdout);
                g_free(name);
                g_free(value);

                sv = js_to_sv(context, js_value, g_hash, FALSE);
                if (is_array) {
                    /* push into the array */
                    av_push(av, sv);
                    JSStringRelease(js_name);
                }
                else {
                    /* get the key, value */
                    gchar *key;
                    U32 klen;

                    key = js_to_str(js_name);
                    JSStringRelease(js_name);
                    klen = strlen(key);
                    hv_store(hv, key, klen, sv, 0);
                    g_free(key);
                }
            }


            /* Remember the reference in case that we will see it once more */
            sv = newRV_inc((is_array ? (SV*) av : (SV*) hv));
            g_hash_table_insert(g_hash, (gpointer)value, (gpointer) sv);
            return sv;
        }

        default:
            return use_globals ? &PL_sv_undef : newSV(0);
    }

}


MODULE = Gtk3::WebKit::WebFrame  PACKAGE = Gtk3::WebKit::WebFrame  PREFIX = webkit_web_frame_


SV*
JSEvaluateScript (WebKitWebFrame *frame, char *script, char *url = NULL, int line_no = 0)
    CODE:
        JSGlobalContextRef context;
        JSStringRef js_script, js_url;
        JSValueRef value;
        JSType type;
        GHashTable *g_hash;

        context = webkit_web_frame_get_global_context(frame);

        js_script = JSStringCreateWithUTF8CString(script);
        js_url = JSStringCreateWithUTF8CString(url);
        value = JSEvaluateScript(context, js_script, NULL, js_url, line_no, NULL);
        JSStringRelease(js_script);
        JSStringRelease(js_url);

        g_hash = g_hash_table_new(g_direct_hash, g_direct_equal);
        RETVAL = js_to_sv(context, value, g_hash, TRUE);
        g_hash_table_unref(g_hash);

    OUTPUT:
        RETVAL
