#include "webkit-perl.h"


MODULE = Gtk3::WebKit::WebFrame  PACKAGE = Gtk3::WebKit::WebFrame  PREFIX = webkit_webframe_


SV* execute_javascript (WebKitWebFrame *frame)
	CODE:
		RETVAL = newSVpv("test", 4);

	OUTPUT:
		RETVAL
