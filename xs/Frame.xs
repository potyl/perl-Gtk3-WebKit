#include "webkit-perl.h"
#include <JavaScriptCore/JavaScript.h>


static const char*
js_get_type (JSGlobalContextRef context, JSValueRef value) {

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


static gboolean
js_is_dom (JSGlobalContextRef context, JSValueRef value) {
    JSStringRef js_constructor = JSStringCreateWithUTF8CString("Node");
    JSObjectRef constructor = JSValueToObject(context, JSObjectGetProperty(context, JSContextGetGlobalObject(context), js_constructor, NULL), NULL);
    JSStringRelease(js_constructor);
    return JSValueIsInstanceOfConstructor(context, value, constructor, NULL);
}


static SV*
js_to_sv (JSGlobalContextRef context, JSValueRef value, GHashTable *g_hash, gboolean use_globals, gboolean is_dom_ancestor) {

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
            gchar *str;
            SV *sv;

            js_value = JSValueToStringCopy(context, value, NULL);
            if (js_value == NULL) {
                return use_globals ? &PL_sv_undef : newSV(0);
            }

            str = js_to_str(js_value);
            JSStringRelease(js_value);
            sv = newSVpv(str, 0);
            g_free(str);
            return sv;
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
            gboolean is_dom;

            is_dom = js_is_dom(context, value);

            if (is_dom_ancestor && is_dom) {
                /* Dumping a real DOM element is problematic because it causes
                   the program to crash if we doit all with recursion. There's
                   some weird stuff in the DOM that should not be serialized
                   back into a SV. What we do instead is to limit the DOM
                   recursion to 1 single node.
                 */
                sv = newSV(0);
                g_hash_table_insert(g_hash, (gpointer)value, (gpointer) sv);
                return sv;
            }


            /* Handle circular references by returning the SV that matches the
               JS object.
             */
            sv = g_hash_table_lookup(g_hash, value);
            if (sv != NULL) {return sv;}

            object = JSValueToObject(context, value, NULL);
            properties = JSObjectCopyPropertyNames(context, object);

            js_prototype = JSObjectGetPrototype(context, object);
            prototype = js_to_json(context, js_prototype);
            if (strcmp(prototype, "[]") == 0) {
                is_array = TRUE;
                av = newAV();
                sv = newRV_inc((SV *) av);
            }
            else {
                is_array = FALSE;
                hv = newHV();
                sv = newRV_inc((SV *) hv);
            }
            g_free(prototype);

            /* Remember the reference in case that we will see it once more */
            g_hash_table_insert(g_hash, (gpointer)value, (gpointer) sv);

            count = JSPropertyNameArrayGetCount(properties);
            for (i = 0; i < count; ++i) {
                JSStringRef js_name;
                JSValueRef jv_value;
                gchar *name, *value;
                SV *sv;

                js_name = JSPropertyNameArrayGetNameAtIndex(properties, i);
                jv_value = JSObjectGetProperty(context, object, js_name, NULL);

                if (JSValueIsObject(context, jv_value)) {
                    JSObjectRef jo_object = JSValueToObject(context, jv_value, NULL);
                     if (JSObjectIsFunction(context, jo_object) || JSObjectIsConstructor(context, jo_object)) {
                        JSStringRelease(js_name);
                        continue;
                    }
                }

                sv = js_to_sv(context, jv_value, g_hash, FALSE, is_dom_ancestor || is_dom);
                if (is_array) {
                    av_push(av, sv);
                    JSStringRelease(js_name);
                }
                else {
                    gchar *key;
                    U32 klen;

                    key = js_to_str(js_name);
                    JSStringRelease(js_name);
                    klen = strlen(key);
                    hv_store(hv, key, klen, sv, 0);
                    g_free(key);
                }
            }

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
        printf("Building Perl tree\n");
        RETVAL = js_to_sv(context, value, g_hash, TRUE, FALSE);
        printf("Perl tree is built\n");
        g_hash_table_unref(g_hash);

    OUTPUT:
        RETVAL
