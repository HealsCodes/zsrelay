/*
   This file is part of zsrelay a srelay port for the iPhone.

   Copyright (C) 2008 Rene Koecher <shirk@bitspin.org>

   Based on srelay 0.4.6 source base Copyright (C) 2001 Tomo.M
   Destributed under the GPL license with original authors permission.

   zsrelay is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or (at
   your option) any later version.

   This program is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>. 
*/

#include "zsrelay.h"
#if defined(FREEBSD) || defined(LINUX)
#include <pwd.h>
#elif  SOLARIS
#include <shadow.h>
#include <crypt.h>
#endif

#define TIMEOUTSEC    30

/* proto types */
int checkpasswd(char *, char *);

int auth_pwd_server(int s)
{
  char buf[512];
  int  r, len;
  char user[256];
  char pass[256];
  struct sockaddr_storage client;
  char client_ip[NI_MAXHOST];
  int  error = 0;
  int  code = 0;

  r = timerd_read(s, buf, sizeof(buf), TIMEOUTSEC, MSG_PEEK);
  if ( r < 2 ) {
    return(-1);
  }
  if (buf[0] != 0x01) { /* current username/password auth version */
    /* error in version */
    return(-1);
  }
  len = buf[1];
  if (len < 1 || len > 255) {
    /* invalid username len */
    return(-1);
  }
  /* read username */
  r = timerd_read(s, buf, 2+len, TIMEOUTSEC, 0);
  if (r < 2+len) {
    /* read error */
    return(-1);
  }
  strncpy(user, &buf[2], len);
  user[len] = '\0';

  /* get passwd */
  r = timerd_read(s, buf, sizeof(buf), TIMEOUTSEC, MSG_PEEK);
  if ( r < 1 ) {
    return(-1);
  }
  len = buf[0];
  if (len < 1 || len > 255) {
    /* invalid password len */
    return(-1);
  }
  /* read passwd */
  r = timerd_read(s, buf, 1+len, TIMEOUTSEC, 0);
  if (r < 1+len) {
    /* read error */
    return(-1);
  }
  strncpy(pass, &buf[1], len);
  pass[len] = '\0';

  /* do authentication */
  r = checkpasswd(user, pass);

  /* logging */
  len = sizeof(struct sockaddr_storage);
  if (getpeername(s, (struct sockaddr *)&client, &len) != 0) {
    client_ip[0] = '\0';
  } else {
    error = getnameinfo((struct sockaddr *)&client, len,
			client_ip, sizeof(client_ip),
			NULL, 0, NI_NUMERICHOST);
    if (error) {
      client_ip[0] = '\0';
    }
  }
  msg_out(norm, "%s 5-U/P_AUTH %s %s.", client_ip,
	  user, r == 0 ? "accepted" : "denied");

  /* erace uname and passwd storage */
  memset(user, 0, sizeof(user));
  memset(pass, 0, sizeof(pass));

  code = ( r == 0 ? 0 : -1 );

  /* reply to client */
  buf[0] = 0x01;  /* sub negotiation version */
  buf[1] = code & 0xff;  /* grant or not */
  r = timerd_write(s, buf, 2, TIMEOUTSEC);
  if (r < 2) {
    /* write error */
    return(-1);
  }
  return(code);   /* access granted or not */
}

int auth_pwd_client(int s, int ind)
{
  char buf[640];
  int  r, ulen, plen;
  FILE *fp;
  char user[256];
  char pass[256];

  /* get username/password */
  setreuid(PROCUID, 0);
  fp = fopen(pwdfile, "r");
  setreuid(0, PROCUID);
  if ( fp == NULL ) {
    /* cannot open pwdfile */
    return(-1);
  }

  r = readpasswd(fp, ind,
		 user, sizeof(user)-1, pass, sizeof(pass)-1);
  fclose(fp);

  if ( r != 0) {
    /* no matching entry found or error */
    goto err_ret;
  }
  ulen = strlen(user);
  if ( ulen < 1 || ulen > 255) {
    /* invalid user name length */
    goto err_ret;
  }
  plen = strlen(pass);
  if ( plen < 1 || plen > 255 ) {
    /* invalid password length */
    goto err_ret;
  }
  /* build auth data */
  buf[0] = 0x01;
  buf[1] = ulen & 0xff;
  memcpy(&buf[2], user, ulen);
  buf[2+ulen] = plen & 0xff;
  memcpy(&buf[2+ulen+1], pass, plen);

  r = timerd_write(s, buf, 3+ulen+plen, TIMEOUTSEC);
  if (r < 3+ulen+plen) {
    /* cannot write */
    goto err_ret;
  }

  /* get server reply */
  r = timerd_read(s, buf, 2, TIMEOUTSEC, 0);
  if (r < 2) {
    /* cannot read */
    goto err_ret;
  }
  if (buf[0] == 0x01 && buf[1] == 0) {
    /* username/passwd auth succeded */
    return(0);
  }
 err_ret:
  /* erace uname and passwd storage */
  memset(user, 0, sizeof(user));
  memset(pass, 0, sizeof(pass));
  return(-1);
}

int checkpasswd(char *user, char *pass)
{
#if defined(FREEBSD) || defined(LINUX)
  struct passwd *pwd;
#elif SOLARIS
  struct spwd *spwd, sp;
  char   buf[512];
#endif
  int matched = 0;

  if (user == NULL) {
    /* user must be specified */
    return(-1);
  }

#if defined(FREEBSD) || defined(LINUX)
  setreuid(PROCUID, 0);
  pwd = getpwnam(user);
  setreuid(0, PROCUID);
  if (pwd == NULL) {
    /* error in getpwnam */
    return(-1);
  }
  if (pwd->pw_passwd == NULL && pass == NULL) {
    /* null password matched */
    return(0);
  }
  if (*pwd->pw_passwd) {
    if (strcmp(pwd->pw_passwd, crypt(pass, pwd->pw_passwd)) == 0) {
      matched = 1;
    }
  }
  memset(pwd->pw_passwd, 0, strlen(pwd->pw_passwd));

#elif SOLARIS
  setreuid(PROCUID, 0);
  spwd = getspnam_r(user, &sp, buf, sizeof buf);
  setreuid(0, PROCUID);
  if (spwd == NULL) {
    /* error in getspnam */
    return(-1);
  }
  if (spwd->sp_pwdp == NULL && pass == NULL) {
    /* null password matched */
    return(0);
  }
  if (*spwd->sp_pwdp) {
    if (strcmp(spwd->sp_pwdp, crypt(pass, spwd->sp_pwdp)) == 0) {
      matched = 1;
    }
  }
  memset(spwd->sp_pwdp, 0, strlen(spwd->sp_pwdp));
#endif

#if defined(FREEBSD) || defined(SOLARIS)
  if (matched) {
    return(0);
  } else {
    return(-1);
  }
#endif
  return(0);
}
