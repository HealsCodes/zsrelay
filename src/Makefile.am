sbin_PROGRAMS = zsrelay

DEFS += -DSYSCONFDIR="\"$(sysconfdir)\""

zsrelay_SOURCES = auth-pwd.c get-bind.c init.c readconf.c util.c socks.c relay.c main.c
zsrelay_LDADD = @LIBS@
zsrelay_LDFLAGS = @LDFLAGS@

