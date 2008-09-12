dnl Process this file with autoconf to produce a configure script.
AC_INIT(src/zsrelay/main.c)
AM_CONFIG_HEADER(config.h)
AC_CANONICAL_TARGET

AM_INIT_AUTOMAKE(zsrelay,0.5.0)

dnl Check if we're cross compiling
AC_MSG_CHECKING(For native or cross compile)

if test "$build_os" == "$host_os"; then
	case "$build_os" in
	  freebsd*)
		OS=FREEBSD
		AC_DEFINE(FREEBSD)
		;;
	  darwin*)
		OS=FREEBSD
		AC_DEFINE(FREEBSD)
		AC_DEFINE(HAVE_NLIST_H)
		;;
	  solaris*)
		OS=SOLARIS
		AC_DEFINE(SOLARIS)
		;;
	  linux*)
		case "$build_cpu" in
		  i*86)
		    OS=LINUX
		    AC_DEFINE(LINUX)
		    ;;
		esac
		;;
	esac
	AC_MSG_RESULT(native)
else
	OS=FREEBSD
	AC_DEFINE(FREEBSD)
	AC_DEFINE(HAVE_NLIST_H)
	AC_MSG_RESULT(cross compile)
fi

CFLAGS="$CFLAGS -O2 -Wall"
LDFLAGS="$LDFLAGS -s"

dnl Local libralies.
if test -d /usr/local/lib; then
    LIBS="-L/usr/local/lib $LIBS"
fi

dnl Solaris 2.6 depends libbind.
dnl libbind default installation base directory.
LIBBIND="/usr/local/bind"

dnl Checks for programs.
GCC=yes
AC_PROG_CC
AC_PROG_OBJC

dnl Check for iPhone cross compile
AC_ARG_ENABLE(iphone-extras,
[--enable-iphone-extras		build with iPhone-only features],
iphoneos="yes",
iphoneos="no")
AC_MSG_CHECKING(whether we should enable iPhone specific features)

if test x$iphoneos == xyes; then
	AC_DEFINE(IPHONE_OS)
	AC_MSG_RESULT([yes])

	dnl export versioning for Cydia

	AC_MSG_CHECKING([which iPhoneOS version to build])
	case $CC in
		arm-apple-darwin8-*)
			AC_SUBST(IPHONE_OS_ARCH, "darwin-arm")
			AC_SUBST(IPHONE_PKG_SUFFIX)
			AC_SUBST(IPHONE_ARCH_SUFFIX, "1legacy")
			AC_DEFINE(IPHONE_OS_RELEASE, 1, [legacy iphone os])
			AC_MSG_RESULT([iphone legacy (1.1.X)])
			AM_CONDITIONAL([IPHONE_OS_RELEASE2], [false])
		;;

		arm-apple-darwin9-*)
			AC_SUBST(IPHONE_OS_ARCH, "iphoneos-arm")
			AC_SUBST(IPHONE_PKG_SUFFIX)
			AC_SUBST(IPHONE_ARCH_SUFFIX)
			AC_DEFINE(IPHONE_OS_RELEASE, 2, [2.x iphone os])
			AC_MSG_RESULT([iphone os 2.X])
			AM_CONDITIONAL([IPHONE_OS_RELEASE2], [true])
		;;

		*)
			AC_MSG_ERROR([

Unsupported build target $host_os.
--enable-iphone-extras requires arm-apple-darwin8/9 as host or build os.])
		;;
	esac

else
	AC_MSG_RESULT([no])
fi

AM_CONDITIONAL([IPHONE_OS], [test x$iphoneos == xyes])

#dnl Checks for libraries.

AC_ARG_WITH(libbind,
[ --with-libbind[[=PATH]]		to use libbind.],
libbind="$withval",
libbind="no")
if test "$libbind" = "yes"; then
  if test -d "$LIBBIND/include"; then
    CFLAGS="-I$LIBBIND/include $CFLAGS"
  fi
elif test "$libbind" != "no"; then
  if test -d "$libbind"/lib; then
    LIBS="-L${libbind}/lib $LIBS"
  fi
  if test -d "$libbind"/include; then
    CFLAGS="-I${libbind}/include $CFLAGS"
  fi
fi

if test "$OS" = "SOLARIS"; then
  if test "$libbind" = "no"; then
    AC_CHECK_LIB(socket, socket)
  else
    AC_CHECK_LIB(xnet, socket)
  fi
  AC_CHECK_LIB(nsl, getaddrinfo,,
	if test "$libbind" != "no"; then
	  AC_CHECK_LIB(bind_r, getaddrinfo,,
	    AC_CHECK_LIB(bind, getaddrinfo,,
	      AC_MSG_ERROR("required functions may not work", -1)))
        else
	  AC_MSG_ERROR("required functions may not work", -1)
	fi
      )
fi

AC_ARG_WITH(libwrap,
[ --with-libwrap[[=PATH|yes|no]]	with tcp_wrapper access control.],
libwrap="$withval",
libwrap="yes")
if test "$libwrap" != "no"; then
   if test "$libwrap" != "yes"; then
      if test -d "$libwrap"; then
         LIBS="-L$libwrap $LIBS"
      fi
   fi
   AC_CHECK_HEADER(tcpd.h, AC_DEFINE(HAVE_TCPD_H), tcpdh="no")
   if test "$tcpdh" != "no"; then
      if test "$OS" = "LINUX"; then
          AC_MSG_CHECKING([for hosts_ctl in -lwrap])
          saveLIBS="$LIBS"
	  LIBS="-lwrap -lnsl $LIBS"
	  AC_COMPILE_IFELSE(
	      AC_LANG_PROGRAM([
[int allow_severity;]
[int deny_severity;]],
[[hosts_ctl();]]),
	AC_DEFINE(HAVE_LIBWRAP)
	AC_MSG_RESULT([yes]),
	LIBS="$saveLIBS"
	AC_MSG_RESULT([no]))
      else
	  AC_CHECK_LIB(wrap, hosts_ctl)
      fi
   fi
fi

AC_ARG_WITH(syslog-fac,
[ --with-syslog-fac=FACILITY	syslog facility (LOG_DAEMON).],
syslogfac="$withval",
syslogfac="no")
if test "$syslogfac" != "no"; then
  if test "$syslogfac" != "yes"; then
    AC_MSG_CHECKING([syslog facility is])
    AC_MSG_RESULT("$withval")
    echo "$withval" |grep "LOG_LOCAL" > /dev/null 2>&1
    r=$?
    if test $r -eq 0; then
      AC_DEFINE_UNQUOTED(LOCAL_FAC, $withval)
    else
      AC_DEFINE_UNQUOTED(SYSLOG_FAC, $withval)
    fi
  fi
fi

AC_ARG_ENABLE(thread,
[ --disable-thread		disable pthread feature.],
thread="$enableval",
thread="yes")
if test "$thread" != "no"; then
    AC_CHECK_HEADER(pthread.h, header_ok="yes", header_ok="no")
    if test "$header_ok" = "yes"; then
	AC_MSG_CHECKING([whether enabling thread])
	save_CFLAGS="$CFLAGS";
	if test "$OS" = "FREEBSD"; then
	    CFLAGS="$CFLAGS -pthread"
	fi
	save_LDFLAGS="$LDFLAGS"
	if test "$OS" = "FREEBSD" -o "$OS" = "LINUX"; then
	    LDFLAGS="$LDFLAGS -pthread"
	elif test "$OS" = "SOLARIS"; then
	    LDFLAGS="$LDFLAGS -lpthread"
	fi

	if test "$build_os" != "$host_os"; then
		AC_MSG_RESULT([enabling threads without check (cross compile)])
		AC_DEFINE(USE_THREAD)
	else

		AC_TRY_RUN(
[#include <pthread.h>
void
init_routine()
{
    return(0);
}
main()
{
    pthread_once_t once_control = PTHREAD_ONCE_INIT;
    pthread_once(&once_control, &init_routine);
    return(0);
}],
	AC_DEFINE(USE_THREAD) AC_MSG_RESULT([yes]),
	CFLAGS="$save_CFLAGS"; LDFLAGS="$save_LDFLAGS"; AC_MSG_RESULT([no])
	)
	fi
    fi
else
	if test x$iphoneos == xyes; then
		AC_MSG_ERROR([pthread support is mandatory when compiling for the iPhone], -1)
	fi
fi

AC_CHECK_LIB(crypt, crypt)

dnl Checks for header files.
AC_HEADER_STDC
AC_HEADER_SYS_WAIT
AC_CHECK_HEADERS(fcntl.h sys/time.h limits.h syslog.h unistd.h\
	sys/resource.h)

dnl Checks for typedefs, structures, and compiler characteristics.
AC_CHECK_TYPES(socklen_t,,,
	[#include <sys/types.h>
#include <sys/socket.h>])

AC_CHECK_TYPES([u_int8_t, u_int16_t, u_int32_t, uint8_t, uint16_t, uint32_t],,,
	[#include <sys/types.h>
#include <netdb.h>])

AC_HEADER_TIME

AC_CHECK_MEMBER(struct sockaddr_dl.sdl_family,
	[AC_DEFINE(HAVE_SOCKADDR_DL_STRUCT)],,
	[#include <sys/types.h>
#include <net/if_dl.h>])

AC_CHECK_MEMBER(struct sockaddr.sa_len,
	[AC_DEFINE(HAVE_SOCKADDR_SA_LEN)],,
	[#include <sys/types.h>
#include <sys/socket.h>])

dnl Checks for library functions.
AC_TYPE_SIGNAL
AC_CHECK_FUNCS(\
		select\
		socket\
		getaddrinfo\
		getnameinfo\
		freeaddrinfo\
		)

dnl iPhone 2.X doesn't like binaries without symbols
if test x$iphoneos = xyes; then
	LDFLAGS=$(echo $LDFLAGS | sed -e's/-s //g')
fi

AC_OUTPUT(Makefile doc/Makefile src/Makefile src/zsrelay/Makefile src/zscmd/Makefile src/prefplug/Makefile debian/control debian/changelog debian/rules)

dnl from acconfig.h
AH_TEMPLATE([FREEBSD],
	[Define if the build system is FreeBSD])
AH_TEMPLATE([SOLARIS],
	[Define if the build system is Solaris])
AH_TEMPLATE([LINUX],
	[Define if the build system is Linux])
AH_TEMPLATE([HAVE_LIMITS_H],
	[Define if you have the <limits.h> header file.])
AH_TEMPLATE([HAVE_TCPD_H],
	[Define if you have the <tcpd.h> header file.])
AH_TEMPLATE([SYSLOG_FAC],
	[Define if you indicate your favor syslog facility.])
AH_TEMPLATE([LOCAL_FAC],
	[Define if you indicate LOG_LOCALx syslog facility.])
AH_TEMPLATE([USE_THREAD],
	[Define if you build a POSIX threading version.])
AH_TEMPLATE([HAVE_SOCKADDR_DL_STRUCT],
	[Define if you have the sockaddr_dl structure.])
AH_TEMPLATE([HAVE_SOCKADDR_SA_LEN],
	[Define if `sa_len' is member of `struct sockaddr'.])
AH_TEMPLATE([HAVE_NLIST_H],
	[Define if you have <mach-o/nlist.h> and want to disable mDNSResponder.])
AH_TEMPLATE([IPHONE_OS],
	[Define if you want to enable iPhone specific features.])
AH_TEMPLATE([IPHONE_OS_RELEASE],
	[Define to the appropriate iPhoneOS major version (1/2)])

