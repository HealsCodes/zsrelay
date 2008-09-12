sbin_PROGRAMS = zscmd

DEFS += -DSYSCONFDIR="\"$(sysconfdir)\""

zscmd_SOURCES = zscmd.m
zscmd_LDADD = @LIBS@
zscmd_LDFLAGS = @LDFLAGS@ -framework CoreFoundation -framework Foundation -multiply_defined suppress -lobjc -Objc

