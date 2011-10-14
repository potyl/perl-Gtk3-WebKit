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
    JSStringRelease(js_str);
    return str;
}


static gchar*
js_to_json (JSGlobalContextRef context, JSValueRef value) {
    JSStringRef js_value;

    js_value = JSValueCreateJSONString(context, value, 0, NULL);
    return js_to_str(js_value);
}


static SV*
js_to_sv (JSGlobalContextRef context, JSValueRef value, gboolean use_globals) {
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

            js_value = JSValueCreateJSONString(context, value, 0, NULL);
            if (js_value != NULL) {
                gchar* str_value;
                SV *val;

                str_value = js_to_str(js_value);
                val = newSVpv(str_value, 0);
                g_free(str_value);
                return val;
            }
            return use_globals ? &PL_sv_undef : newSV(0);
        }

        case kJSTypeObject:
        {
            JSPropertyNameArrayRef properties;
            JSObjectRef object;
            size_t count, i;

            object = (JSObjectRef) value;
            properties = JSObjectCopyPropertyNames(context, object);

            count = JSPropertyNameArrayGetCount(properties);
            for (i = 0; i < count; ++i) {
                JSStringRef js_name;
                JSValueRef js_value;
                gchar *name, *value;

                js_name = JSPropertyNameArrayGetNameAtIndex(properties, i);
                js_value = JSObjectGetProperty(context, object, js_name, NULL);

                name = js_to_str(js_name);
                value = js_to_json(context, js_value);
                printf("[%2d] Property: %s => %s\n", i, name, value);
                g_free(name);
                g_free(value);
            }

            return newSVpv("{OBJECT}", 0);
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

        context = webkit_web_frame_get_global_context(frame);

        js_script = JSStringCreateWithUTF8CString(script);
        js_url = JSStringCreateWithUTF8CString(url);
        value = JSEvaluateScript(context, js_script, NULL, js_url, line_no, NULL);
        JSStringRelease(js_script);
        JSStringRelease(js_url);

        RETVAL = js_to_sv(context, value, TRUE);

    OUTPUT:
        RETVAL
