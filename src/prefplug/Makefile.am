noinst_PROGRAMS = ZSRelaySettings

DEFS += -DSYSCONFDIR="\"$(sysconfdir)\""
INCLUDES = -I$(srcdir)/../zsipc

ZSRelaySettings_SOURCES = ZSRelaySettings.m
ZSRelaySettings_LDADD = @LIBS@ -lobjc -lzsipc
ZSRelaySettings_LDFLAGS = -L../zsipc -bundle -framework CoreFoundation -framework Foundation -framework UIKit -framework Preferences -bind_at_load -multiply_defined suppress -Objc

