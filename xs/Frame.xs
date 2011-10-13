#include "webkit-perl.h"
#include <JavaScriptCore/JavaScript.h>


static
const char*
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


static
SV*
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
                gint max_size;
                gchar* str_value;
                SV *val;

                max_size = JSStringGetMaximumUTF8CStringSize(js_value);
                str_value = g_malloc(max_size);
                JSStringGetUTF8CString(js_value, str_value, max_size);
                JSStringRelease(js_value);

                val = newSVpv(str_value, 0);
                g_free(str_value);
                return val;
            }
            return use_globals ? &PL_sv_undef : newSV(0);
        }

        case kJSTypeObject:
            return newSVpv("{OBJECT}", 0);

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
