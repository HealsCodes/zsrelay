noinst_PROGRAMS = ZSRelaySettings Demo

DEFS += -DSYSCONFDIR="\"$(sysconfdir)\""
INCLUDES = -I$(srcdir)/../zsipc -I$(srcdir)/../../compat/include -I$(sysroot)/Library/Frameworks/UIKit.framework/Headers

ZSRelaySettings_SOURCES = ZSRelaySettings.m
ZSRelaySettings_LDADD = @LIBS@ -lobjc -lzsipc
ZSRelaySettings_LDFLAGS = -L../zsipc -bundle -framework CoreFoundation -framework Foundation -framework UIKit -framework Preferences -bind_at_load -multiply_defined suppress -Objc

Demo_SOURCES = Demo.m
Demo_LDADD = @LIBS@ -lobjc
Demo_LDFLAGS = -L../zsipc -bundle -framework CoreFoundation -framework Foundation -framework UIKit -framework Preferences -bind_at_load -multiply_defined suppress -Objc -undefined dynamic_lookup

