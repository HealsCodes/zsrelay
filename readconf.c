/*
  readconf.c:
  $Id: readconf.c,v 1.7 2003/04/13 21:13:25 bulkstream Exp $

Copyright (C) 2001 Tomo.M (author).
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
3. Neither the name of the author nor the names of its contributors
   may be used to endorse or promote products derived from this software
   without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/

#include "zsrelay.h"

/* prototypes */
char *skip   __P((char *));
char *spell  __P((char *));
void add_entry __P((struct rtbl *, struct rtbl *, int));
void parse_err __P((int, int, char *));
int dot_to_masklen __P((char *));
int str_to_addr __P((char *, struct bin_addr *));

#define MAXLINE  1024
#define SP        040
#define HT        011
#define NL        012
#define VT        013
#define NP        014
#define CR        015

#define SPACES(c) (c == SP || c == HT || c == VT || c == NP)
#define DELIMS(c) (c == '\0' || c == '#' || c == ';' || c == NL || c == CR)

#define PORT_MIN  0
#define PORT_MAX  65535

struct rtbl *proxy_tbl;    /* proxy routing table */
int    proxy_tbl_ind;         /* next entry indicator */

/*
  config format:
        #   comment line
	# dest_ip[/mask]          port-low-port-hi  next-proxy  [porxy-port]
	192.168.1.2/255.255.255.0   1-100           172.16.5.1  1080
	172.17.5.0/24               901             102.100.2.1 11080
	172.17.8.0/16               any
	0.0.0.0/0.0.0.0             0-32767         10.1.1.2    1080
        
  note:
        port-low, port-hi includes specified ports.
	port numbers must be port-low <= port-hi.
	separator of port-low and port-hi is '-'. no space chars.
	port-low = NULL (-port-hi) means 0 to port-hi.
	port-hi=NULL (port-low-) means port-low to 65535.
	           ... so, single '-' means 0 to 65535 (?).
	special port 'any' means 0-65535
	no next-proxy means "direct" connect to destination.
*/

int readconf(FILE *fp)
{
  char     *p, *q, *r, *tok;
  int      len;
  int      n = 0;
  char     *any = "any";
  char     buf[MAXLINE];
  struct rtbl tmp;
  struct rtbl tmp_tbl[MAX_ROUTE];
  struct rtbl *new_proxy_tbl;
  int      new_proxy_tbl_ind = 0;

  while (fp && fgets(buf, MAXLINE-1, fp) != NULL) {
    memset(&tmp, 0, sizeof(struct rtbl));
    p = buf;
    n++;

    if ((p = skip(p)) == NULL) { /* comment line or something */
      continue;
    }

    /* destination */
    tok = p; p = spell(p);
    q = strchr(tok, '/');
    /* check wheather dest has address mask */
    if (q != NULL) {
      *q++ = '\0';  /* delimit */
      tmp.mask = 0;
      len = strlen(q);
      if ( len > 0 ) {
	if ((r = strchr(q, '.')) != NULL) { /* may be dotted decimal */
	  if ((tmp.mask = dot_to_masklen(q)) < 0) {
	      parse_err(warn, n, "parse_addr error.");
	      continue;
	  }
	} else {
	  tmp.mask = atoi(q);
	  if ( errno == ERANGE ) {
	    parse_err(warn, n, "parse mask length.");
	    continue;
	  }
	}
      }
    }

    /* set destination to tmp.dest */
    if (str_to_addr(tok, &tmp.dest) != 0) {
      parse_err(warn, n, "parse_addr error.");
      continue;
    }

    if ((p = skip(p)) == NULL) {
      parse_err(warn, n, "dest port missing or invalid, ignore this line.");
      continue;
    }

    /* dest port */
    tok = p; p = spell(p);
    if ((q = strchr(tok, '-')) != NULL ) {
      if (tok == q) {           /* special case '-port-hi' */
	tmp.port_l = PORT_MIN;
      } else {
	*q = '\0';
	tmp.port_l = atoi(tok);
      }
      if (*++q == '\0') {       /* special case 'port-low-' */
	tmp.port_h = PORT_MAX;
      } else {
	tmp.port_h = atoi(q);
      }
    } else if ((strncasecmp(tok, any, strlen(any))) == 0) {
      tmp.port_l = PORT_MIN;
      tmp.port_h = PORT_MAX;
    } else {     /* may be single port */
      tmp.port_l = tmp.port_h = atoi(tok);
      if ( errno == ERANGE ) {
	parse_err(warn, n, "parse dest port number.");
	continue;
      }
    }
    if ((tmp.port_l > tmp.port_h) || (tmp.port_h == 0)) {
      parse_err(warn, n, "dest port range is invalid.");
      continue;
    }

    if ((p = skip(p)) == NULL) {        /* no proxy entry */
      add_entry(&tmp, tmp_tbl, new_proxy_tbl_ind++);
      continue;
    }

    /* proxy */
    tok = p; p = spell(p);
    if (str_to_addr(tok, &tmp.proxy) != 0) {
      parse_err(warn, n, "proxy address parse error.");
      continue;
    }

    /* proxy port */
    if ((p = skip(p)) == NULL) { /* proxy-port is ommited */
      tmp.port = SOCKS_PORT;     /* defaults to socks port */
      add_entry(&tmp, tmp_tbl, new_proxy_tbl_ind++);
      /* remaining data is ignored */
      continue;
    } else {
      tok = p; p = spell(p);
      tmp.port = atoi(tok);
      if ( errno == ERANGE ) {
	parse_err(warn, n, "parse proxy port number.");
	continue;
      }
      add_entry(&tmp, tmp_tbl, new_proxy_tbl_ind++);
    }
  }

  if ( new_proxy_tbl_ind <= 0 ) { /* no valid entries */
    parse_err(warn, n, "no valid entries found. using default.");
    new_proxy_tbl_ind = 1;
    memset(tmp_tbl, 0, sizeof(struct rtbl));
    tmp_tbl[0].port_l = PORT_MIN; tmp_tbl[0].port_h = PORT_MAX;
  }

  /* allocate suitable memory space to proxy_tbl */
  new_proxy_tbl = (struct rtbl *)malloc(sizeof(struct rtbl)
					* new_proxy_tbl_ind);
  if ( new_proxy_tbl == (struct rtbl *)0 ) {
    /* malloc error */
    return(-1);
  }
  memcpy(new_proxy_tbl, tmp_tbl,
	 sizeof(struct rtbl) * new_proxy_tbl_ind);

  if (proxy_tbl != NULL) { /* may holds previous table */
    free(proxy_tbl);
  }
  proxy_tbl     = new_proxy_tbl;
  proxy_tbl_ind = new_proxy_tbl_ind;
  return(0);
}

/*
 *  skip spaces.
 *  return:  0  if delimited.
 *  return: ptr to next token.
 */
char *skip(char *s)
{
  while (SPACES(*s))
    s++;
  if (DELIMS(*s))
    return(NULL);
  else
    return(s);
}

char *spell(char *s) {
  while (!SPACES(*s) && !DELIMS(*s))
    s++;
  *s++ = '\0';
  return(s);
}

void add_entry(struct rtbl *r, struct rtbl *t, int ind)
{
  if (ind >= MAX_ROUTE) {
    /* error in add_entry */
    return;
  }
  memcpy(&t[ind], r, sizeof(struct rtbl));
}

void parse_err(int sev, int line, char *msg)
{
  msg_out(sev, "%s: line %d: %s\n", CONFIG, line, msg);
}

int str_to_addr(char *addr, struct bin_addr *dest)
{
  char     *q;
  int      len, i, c;
  struct addrinfo hints, *res0, *res;
  int      error;
  struct sockaddr_in   *sa;
  struct sockaddr_in6  *sa6;

  /* check address type */
  q = strchr(addr, ':');
  if (q != NULL) {
    dest->atype = S5ATIPV6;
  } else {
    dest->atype = S5ATIPV4;
    len = strlen(addr);
    for (i=0; i<len; i++) {
      c = *(addr+i);
      if ( c != '.' && (c < '0' || c > '9')) {
	/* addr contains non-numeric character */
	dest->atype = S5ATFQDN;
	break;
      }
    }
  }

  error = 0;
  /* copy address to structure */
  switch (dest->atype) {
  case S5ATFQDN:
    if ((len = strlen(addr)) > 0 && len < 256) {
      dest->len_fqdn = len;
      strncpy(dest->fqdn, addr, len);
    } else {
      error++;
    }
    break;

  case S5ATIPV4:
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_flags = AI_NUMERICHOST;
    error = getaddrinfo(addr, NULL, &hints, &res0);
    if (!error) {
      int done = 0;
      for (res = res0; res; res = res->ai_next) {
	if (res->ai_family != AF_INET)
	  continue;
	sa = (struct sockaddr_in *)res->ai_addr;
	memcpy(dest->v4_addr, &sa->sin_addr, sizeof(struct in_addr));
	done = 1;
	break;
      }
      if (!done)
	error++;
      freeaddrinfo(res0);
    }
    break;

  case S5ATIPV6:
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_INET6;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_flags = AI_NUMERICHOST;
    error = getaddrinfo(addr, NULL, &hints, &res0);
    if (!error) {
      int done = 0;
      for (res = res0; res; res = res->ai_next) {
	if (res->ai_family != AF_INET6)
	  continue;
	sa6 = (struct sockaddr_in6 *)res->ai_addr;
	memcpy(dest->v6_addr, &sa6->sin6_addr, sizeof(struct in6_addr));
	dest->v6_scope = sa6->sin6_scope_id;
	done = 1;
	break;
      }
      if (!done)
	error++;
      freeaddrinfo(res0);
    }
    break;
  default:
    error++;
    break;
  }
  return error;
}

int dot_to_masklen(char *addr)
{
  /* Address family dependant */

  struct addrinfo  hints, *res;
  int    i, error;
  u_int32_t xx;
  struct sockaddr_in *sin;

  memset(&hints, 0, sizeof(hints));
  hints.ai_socktype = SOCK_STREAM;
  hints.ai_family = AF_INET;
  hints.ai_flags = AI_NUMERICHOST;
  error = getaddrinfo(addr, NULL, &hints, &res);
  if (error) {
    return -1;
  }
  if (res->ai_family != AF_INET) {  /*** !!! ***/
    freeaddrinfo(res);
    return -1;
  }

  sin = (struct sockaddr_in *)res->ai_addr;
  xx = ntohl(sin->sin_addr.s_addr) & 0xffffffff;
  for (i=32; i>0; i--) {
    if ( xx & 1 )
      break;
    xx >>= 1;
  }
  freeaddrinfo(res);
  return i;
}

/*
  readpasswd:
	read from fp, search user and set pass.
	it is little bit dangerous, that this routine will
	over-writes arguemts 'user' and 'pass' contents.
    File format:
    # comment
    # proxy-host-ip/name   user    passwd
    10.1.1.117             tomo    hogerata
    dtmp163.kddi.com       bob     foobar

*/
int readpasswd(FILE *fp, int ind, 
	       char *user, int ulen, char *pass, int plen)
{
  char     buf[MAXLINE];
  char     *p, *tok;
  int      len;
  struct   bin_addr addr;
  int      matched;

  memset(&addr, 0, sizeof(addr));

  if (memcmp(&(proxy_tbl[ind].proxy), &addr, sizeof(addr)) == 0) {
    /* it must be no-proxy. how did you fetch up here ?
       any way, you shouldn't be hanging aroud.
    */
    return(0);
  }
  while (fgets(buf, MAXLINE-1, fp) != NULL) {
    p = buf; tok = 0;
    if ((p = skip(p)) == NULL) { /* comment line or something */
      continue;
    }
    /* proxy host ip/name entry */
    tok = p; p = spell(p); len = strlen(tok);
    if (str_to_addr(tok, &addr) != 0)  /* error */
      continue;

    if (proxy_tbl[ind].proxy.atype != addr.atype) {
      /* address type mismatched */
      continue;
    }

    matched = 0;
    switch (addr.atype) {
    case S5ATFQDN:
      if (strncasecmp(proxy_tbl[ind].proxy.fqdn,
		      addr.fqdn, proxy_tbl[ind].proxy.len_fqdn) == 0)
	matched++;
      break;
    case S5ATIPV4:
      if (memcmp(proxy_tbl[ind].proxy.v4_addr, addr.v4_addr, 4) == 0)
	matched++;
      break;
    case S5ATIPV6:
      if (memcmp(proxy_tbl[ind].proxy.v6_addr, addr.v6_addr, 16) == 0)
	matched++;
      break;
    default:
      break;
    }
    if (!matched)
      continue;

    if ((p = skip(p)) == NULL) {
      /* insufficient fields, ignore this line */
      continue;
    }

    tok = p; p = spell(p); len = strlen(tok); 
    if (len <= ulen) {
      strncpy(user, tok, len);
      user[len] = '\0';
    } else {
      /* invalid length, ignore this line */
      continue;
    }

    if ((p = skip(p)) == NULL) {
      /* insufficient fields, ignore this line */
      continue;
    }

    tok = p; p = spell(p); len = strlen(tok);
    if (len <= plen) {
      strncpy(pass, tok, len);
      pass[len] = '\0';
      /* OK, this is enough, */
      return(0);
    } else {
      /* invalid length, ignore this line */
      continue;
    }
  }
  /* matching entry not found or error */
  return(-1);
}

#if 0
/* how to do with #if 1 */
/* make readconf.o util.o
   gcc -pthread -o readconf readconf.o util.o
   ./readconf conf
*/
/* dummy */
char *pidfile;
int cur_child;
int sig_queue[2];
int threading;
pthread_t main_thread;
char *config;
/* dummy */

int resolv_host(struct bin_addr *addr, char *p, int l)
{
  int    len, error;
  struct sockaddr_storage ss;
  struct sockaddr_in  *sa;
  struct sockaddr_in6 *sa6;

  struct in6_addr in6addr_any = IN6ADDR_ANY_INIT;
  struct in_addr  inaddr_any;

  inaddr_any.s_addr = INADDR_ANY;


  memset(&ss, 0, sizeof(ss));
  switch (addr->atype) {
  case S5ATIPV4:
    len = sizeof(struct sockaddr_in);
    sa = (struct sockaddr_in *)&ss;
    sa->sin_family = AF_INET;
    memcpy(&sa->sin_addr, &(addr->v4_addr), len);
    sa->sin_len = len;
    error = getnameinfo((struct sockaddr *)sa, len,
			p, l, NULL, 0, NI_NUMERICHOST);
    if (error) {
      strncpy(p, "<error>", l);
    }
    if (memcmp(&(addr->v4_addr), &inaddr_any,
	       sizeof(inaddr_any)) == 0) {
      strncat(p, "(INADDR_ANY)", l);
    }
    break;
  case S5ATIPV6:
    len = sizeof(struct sockaddr_in6);
    sa6 = (struct sockaddr_in6 *)&ss;
    sa6->sin6_family = AF_INET6;
    memcpy(&sa6->sin6_addr, &(addr->v6_addr), len);
    sa6->sin6_len = len;
    error = getnameinfo((struct sockaddr *)sa6, len,
			p, l, NULL, 0,	NI_NUMERICHOST);
    if (error) {
      strncpy(p, "<error>", l);
    }
    if (memcmp(&(addr->v6_addr), &in6addr_any,
	       sizeof(in6addr_any)) == 0) {
      strncat(p, "(IN6ADDR_ANY)", l);
    }
    break;
  case S5ATFQDN:
  default:
    strncpy(p, addr->fqdn, addr->len_fqdn);
    p[addr->len_fqdn] = '\0';
    break;
  }
  return 0;
}

void dump_entry()
{
  int    i;
  char   host[NI_MAXHOST];

  for (i=0; i < proxy_tbl_ind; i++) {
    fprintf(stdout, "--- %d ---\n", i);
    fprintf(stdout, "atype: %d\n", proxy_tbl[i].dest.atype);

    resolv_host(&proxy_tbl[i].dest, host, sizeof(host));
    fprintf(stdout, "dest: %s\n", host);

    fprintf(stdout, "mask: %d\n", proxy_tbl[i].mask);
    fprintf(stdout, "port_l: %u\n", proxy_tbl[i].port_l);
    fprintf(stdout, "port_h: %u\n", proxy_tbl[i].port_h);

    resolv_host(&proxy_tbl[i].proxy, host, sizeof(host));
    fprintf(stdout, "proxy: %s\n", host);
    fprintf(stdout, "port: %u\n", proxy_tbl[i].port);
  }
}

#if 0
void checkpwd(char *user)
{
  FILE *fp;
  char pass[256];

  if ( (fp = fopen(PWDFILE, "r")) == NULL ) {
    fprintf(stderr, "cannot open %s\n", PWDFILE);
    return;
  }
  if (readpasswd(fp, user, pass, 255) == 0) {
    fprintf(stdout, "%s\n", pass);
  }

}
#endif

int main(int argc, char **argv) {

  FILE *fp;

  if (argc < 2) {
    fprintf(stderr, "need args\n");
    return(1);
  }

  if ( (fp = fopen(argv[1], "r")) == NULL ) {
    fprintf(stderr, "can't open %s\n", argv[1]);
    return(1);
  }
  readconf(fp);
  fclose(fp);

  dump_entry();
  return(0);

}
#endif
