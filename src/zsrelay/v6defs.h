/*
   This file is part of zsrelay a srelay port for the iPhone.

   Copyright (C) 2008 Rene Koecher <shirk@bitspin.org>

   Based on srelay 0.4.6 source base Copyright (C) 2003 Tomo.M
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
#ifndef __V6DEFS_H
#define __V6DEFS_H 1

#ifndef AF_INET6
#define AF_INET6        24
#endif

#ifndef PF_INET6
#define PF_INET6        AF_INET6
#endif
struct in6_addr
{
  u_int8_t        s6_addr[16];
};

struct sockaddr_in6
{
#ifdef  HAVE_SOCKADDR_SA_LEN
  u_int8_t        sin6_len;       /* length of this struct */
  u_int8_t        sin6_family;    /* AF_INET6 */
#else
  u_int16_t       sin6_family;    /* AF_INET6 */
#endif
  u_int16_t       sin6_port;      /* transport layer port # */
  u_int32_t       sin6_flowinfo;  /* IPv6 flow information */
  struct in6_addr sin6_addr;      /* IPv6 address */
  u_int32_t       sin6_scope_id;  /* set of interfaces for a scope */
};

#ifndef IN6ADDR_ANY_INIT
#define IN6ADDR_ANY_INIT        {{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}}
#endif
#if defined(NEED_SOCKADDR_STORAGE) || !defined(HAS_INET6_STRUCTS)
#define __SS_MAXSIZE 128
#define __SS_ALLIGSIZE (sizeof (long))

struct sockaddr_storage
{
#ifdef  HAVE_SOCKADDR_SA_LEN
  u_int8_t        ss_len;       /* address length */
  u_int8_t        ss_family;    /* address family */
  char            __ss_pad1[__SS_ALLIGSIZE - 2 * sizeof(u_int8_t)];
  long            __ss_align;
  char            __ss_pad2[__SS_MAXSIZE - 2 * __SS_ALLIGSIZE];
#else
  u_int16_t       ss_family;    /* address family */
  char            __ss_pad1[__SS_ALLIGSIZE - sizeof(u_int16_t)];
  long            __ss_align;
  char            __ss_pad2[__SS_MAXSIZE - 2 * __SS_ALLIGSIZE];
#endif
};
#endif
#endif /* __V6DEFS_H */

