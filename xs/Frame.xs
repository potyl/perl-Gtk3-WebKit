#include "webkit-perl.h"
#include <JavaScriptCore/JavaScript.h>


const char* get_type (JSGlobalContextRef context, JSValueRef value) {
    JSType type = JSValueGetType(context, value);

    switch (type) {
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

        printf("value = %p\n", value);
        printf("type = %s\n", get_type(context, value));

        type = JSValueGetType(context, value);
        if (type == kJSTypeObject) {
            RETVAL = newSVpv("{}", 2);
        }
        else {
            JSStringRef js_value;
            gint max_size;
            gchar* str_value;

            js_value = JSValueCreateJSONString(context, value, 0, NULL);
            printf("value = %p\n", js_value);
            /* printf("type = %s\n", get_type(context, js_value)); */
            if (js_value != NULL) {
                max_size = JSStringGetMaximumUTF8CStringSize(js_value);
                str_value = g_malloc(max_size);
                JSStringGetUTF8CString(js_value, str_value, max_size);
                JSStringRelease(js_value);

                RETVAL = newSVpv(str_value, 0);
                g_free(str_value);
            }
            else {
                RETVAL = &PL_sv_undef;
            }
        }

    OUTPUT:
        RETVAL
