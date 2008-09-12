noinst_PROGRAMS = ZSRelaySettings

DEFS += -DSYSCONFDIR="\"$(sysconfdir)\""

ZSRelaySettings_SOURCES = ZSRelaySettings.m
ZSRelaySettings_LDADD = @LIBS@
ZSRelaySettings_LDFLAGS = -bundle -framework CoreFoundation -framework Foundation -framework UIKit -framework Preferences -bind_at_load -multiply_defined suppress -lobjc -ObjC

