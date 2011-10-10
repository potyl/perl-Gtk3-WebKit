#include "webkit-perl.h"
#include <JavaScriptCore/JavaScript.h>


MODULE = Gtk3::WebKit::WebFrame  PACKAGE = Gtk3::WebKit::WebFrame  PREFIX = webkit_web_frame_


SV*
JSEvaluateScript (WebKitWebFrame *frame, char *script, char *url = NULL, int line_no = 0)
    CODE:
        JSGlobalContextRef context;
        JSStringRef js_script, js_url;
        JSValueRef value;

        context = webkit_web_frame_get_global_context(frame);

        js_script = JSStringCreateWithUTF8CString(script);
        js_url = JSStringCreateWithUTF8CString(url);
        value = JSEvaluateScript(context, js_script, NULL, js_url, line_no, NULL);
        JSStringRelease(js_script);
        JSStringRelease(js_url);

        if (! JSValueIsString(context, value)) {
            printf("Value is not a string\n");
            RETVAL = &PL_sv_undef;
        }
        else {
            JSStringRef js_value;
            gint max_size;
            gchar* str_value;

            js_value = JSValueToStringCopy(context, value, NULL);
            max_size = JSStringGetMaximumUTF8CStringSize(js_value);
            str_value = g_malloc(max_size);
            JSStringGetUTF8CString(js_value, str_value, max_size);
            JSStringRelease(js_value);

            RETVAL = newSVpv(str_value, 0);
            g_free(str_value);
        }

    OUTPUT:
        RETVAL
