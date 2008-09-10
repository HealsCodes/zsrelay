if IPHONE_OS
sbin_PROGRAMS = zsrelay zscmd
else
sbin_PROGRAMS = zsrelay
endif

DEFS += -DSYSCONFDIR="\"$(sysconfdir)\""

zsrelay_SOURCES = auth-pwd.c get-bind.c init.c readconf.c util.c socks.c relay.c main.c
zsrelay_LDADD = @LIBS@
zsrelay_LDFLAGS = @LDFLAGS@

if IPHONE_OS
zscmd_SOURCES = zscmd.c
zscmd_LDADD = @LIBS@
zscmd_LDFLAGS = @LDFLAGS@ -framework CoreFoundation

zsrelay_SOURCES += ZSRelayApp.m ZSRelayApp+Settings.m ZSRelayApp+IOKit.m ZSRelayApp+Icons.m ZSRelayApp+Notify.m
zsrelay_LDFLAGS += -framework CoreFoundation -framework Foundation -framework IOKit -framework UIKit -multiply_defined suppress -lobjc -ObjC
endif

