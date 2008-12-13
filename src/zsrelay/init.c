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

#include <sys/param.h>
#include "zsrelay.h"

char **str_serv_sock; /* to use tcp_wrappers validation */
int       *serv_sock; /* */
int       serv_sock_ind;

fd_set allsock;
int    maxsock;
int    sig_queue[2];

int
serv_init(char *ifs)
{
    struct addrinfo  hints, *res, *res0;
    int    error;
    int    i, dup;
    size_t len;
    char   *line, *h, *p, *q;
    int    s;
    char   hbuf[NI_MAXHOST], sbuf[NI_MAXSERV];
    char   tmp_str_serv_sock[NI_MAXHOST+NI_MAXSERV+1];
    const  int on = 1;

    if (ifs == NULL || *ifs == '\0')
      {
	str_serv_sock = malloc(sizeof(char *) * MAX_SOCKS);
	if (str_serv_sock == NULL)
	  return -1;

	serv_sock = malloc(sizeof(int) * MAX_SOCKS);
	if (serv_sock == NULL)
	  return -1;

	serv_sock_ind = 0;
	maxsock = 0;
	FD_ZERO(&allsock);

	return(0);
      }

    len = strlen(ifs);
    if (len > NI_MAXHOST + NI_MAXSERV + 1)
      /* ifs line too long */
      return(-1);

    line = strdup(ifs);
    if (line == NULL) /* malloc failed */
      return(-1);

    h = line;

    if ( *h == '[' )
      {    /* Escaped Numeric address */
	h++;
	if ( (q = strchr(h, ']')) == NULL )
	  {
	    /* Escaped address format error */
	    free(line);
	    return(-1);
	  }

	*q = '\0';
	p = q + 1;     /* port assignment may follow */
	if (*p == ':') /* separator */
	  p++;

      }
    else
      {
	p = strchr(h, ':');
	if (p != NULL) /* a port assignment may followed */
	  *p++ = '\0';
      }

    if ( p == NULL || *p == '\0' )
      {
	/* set socks default port */
	snprintf(sbuf, sizeof(sbuf), "%d", SOCKS_PORT);
	p = sbuf;
      }

    memset(&hints, 0, sizeof(hints));
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_flags = AI_PASSIVE;
    error = getaddrinfo(*h == '\0' ? NULL : h, p, &hints, &res0);
    free(line);

    if (error)
      /* getaddrinfo error */
      return(-1);

    for (res = res0; res && serv_sock_ind < MAX_SOCKS; res = res->ai_next)
      {
	error = getnameinfo(res->ai_addr, res->ai_addrlen,
			    hbuf, sizeof(hbuf), sbuf, sizeof(sbuf),
			    NI_NUMERICHOST | NI_NUMERICSERV);
	if (error)
	  /* getnameinfo error */
	  return(-1);

	strncpy(tmp_str_serv_sock, hbuf, sizeof(hbuf));
	/* replace ':' char to '_' for using str in hosts_access */
	for ( i = 0; i < sizeof(hbuf); i++ )
	  {
	    if (hbuf[i] == ':')
	      hbuf[i] = '_';
	  }

	strncat(tmp_str_serv_sock, "_", strlen("_"));
	strncat(tmp_str_serv_sock, sbuf, sizeof(sbuf));
	for ( i = 0, dup = 0; i < serv_sock_ind; i++ )
	  {
	    if ( str_serv_sock[i] != NULL )
	      {
		if (strncmp(tmp_str_serv_sock, str_serv_sock[i],
			    sizeof(tmp_str_serv_sock)) == 0)
		  {
		    dup++;
		    break;
		  }
	      }
	  }

	if (!dup)
	  {
	    s = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
	    if ( s < 0 )
	      continue;

	    if ( s >= FD_SETSIZE )
	      {   /* avoid FD_SET overrun */
		close(s);
		continue;
	      }

	    if (setsockopt(s, SOL_SOCKET, SO_REUSEADDR,
			   (char *)&on, sizeof on) < 0)
	      {
		perror("setsockopt: SO_REUSEADDR");
		close(s);
		continue;
	      }
#ifdef IPV6_V6ONLY
	    if (res->ai_family == AF_INET6 &&
		setsockopt(s, IPPROTO_IPV6, IPV6_V6ONLY,
			   &on, sizeof(on)) < 0)
	      {
		perror("setsockopt: IPV6_V6ONLY");
		close(s);
		continue;
	      }
#endif
	    if (bind(s, res->ai_addr, res->ai_addrlen) < 0 )
	      {
		close(s);
		continue;
	      }
	    if (listen(s, 64) < 0)
	      {
		close(s);
		continue;
	      }
	    str_serv_sock[serv_sock_ind] = strdup(tmp_str_serv_sock);
	    if (str_serv_sock[serv_sock_ind] == NULL)
	      {
		/* malloc failed */
		close(s);
		continue;
	      }
	    serv_sock[serv_sock_ind] = s;
	    FD_SET(s, &allsock);
	    maxsock = MAX(s, maxsock);
	    serv_sock_ind++;
	  }
      }

    if (serv_sock_ind == 0)
      {
	msg_out(warn, "no server socket prepared, exitting...\n");
	return(-1);
      }

    return(0);
}

int
queue_init()
{
    if (pipe(sig_queue) != 0)
      return(-1);

    if (sig_queue[0] > 0)
      {
	FD_SET(sig_queue[0], &allsock);
	maxsock = MAX(sig_queue[0], maxsock);
      }
    else
      return(-1);

    return(0);
}

#if 0
/*
   to test ...
   ./configure
   make init.o
   make util.o
   cc -o test-ini init.o util.o
   ./test-ini 123.123.123.123:1111
   */
int cur_child;
char *pidfile;
int threading;
int pthread_equal(pthread_t x, pthread_t y){return 0;}
pthread_t main_thread;
char *config;
int readconf(FILE *f){return 0;}

int main(int argc, char **argv) {

  int i;

  if (argc > 1) {
    serv_init(NULL);
    serv_init(argv[1]);
  } else {
    fprintf(stderr,"need args\n");
  }
  for (i = 0; i < serv_sock_ind; i++) {
    fprintf(stdout, "%d: %s\n", serv_sock[i], str_serv_sock[i]);
  }
  return(0);
}

#endif

