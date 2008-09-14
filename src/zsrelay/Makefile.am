sbin_PROGRAMS = zsrelay

DEFS += -DSYSCONFDIR="\"$(sysconfdir)\""

zsrelay_SOURCES = auth-pwd.c get-bind.c init.c readconf.c util.c socks.c relay.c main.c
zsrelay_LDADD = @LIBS@
zsrelay_LDFLAGS = @LDFLAGS@

if IPHONE_OS
INCLUDES = -I$(srcdir)/../zsipc
zsrelay_SOURCES += ZSRelayApp.m ZSRelayApp+Settings.m ZSRelayApp+IOKit.m ZSRelayApp+Icons.m ZSRelayApp+Notify.m libzsipc.a
zsrelay_LDADD   += -lobjc -lzsipc
zsrelay_LDFLAGS += -L../zsipc/ -framework CoreFoundation -framework Foundation -framework IOKit -framework Message -framework UIKit -multiply_defined suppress
if IPHONE_OS_RELEASE2
zsrelay_LDFLAGS += -framework AudioToolbox
endif
zsrelay_LDFLAGS += -framework GraphicsServices
endif

