sbin_PROGRAMS = zscmd

INCLUDES = -I$(srcdir)/../zsipc
zscmd_SOURCES = zscmd.m
zscmd_LDADD = @LIBS@ -lzsipc
zscmd_LDFLAGS = @LDFLAGS@ -L../zsipc -framework CoreFoundation -framework Foundation -multiply_defined suppress -lobjc -Objc

