noinst_PROGRAMS = ZSLauncher

DEFS += -DSYSCONFDIR="\"$(sysconfdir)\""
INCLUDES = -I$(srcdir)/../zsipc

ZSLauncher_SOURCES = main.m ZSLauncher.m ZSLauncher+Apple80211.m
ZSLauncher_LDADD = @LIBS@ -lobjc -ldl
ZSLauncher_LDFLAGS = -L../zsipc -framework CoreFoundation -framework Foundation -framework UIKit -bind_at_load -multiply_defined suppress -Objc

