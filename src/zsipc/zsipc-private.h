/*
   This file is part of zsrelay a srelay port for the iPhone.

   Copyright (C) 2008 Rene Koecher <shirk@bitspin.org>

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

#ifndef __ZSIPC_PRIVATE_H
#define __ZSIPC_PRIVATE_H 1

#include "zsipc.h"

extern const CFStringRef ZSMsgDoTrafficStats;

ZSIPCRef ZSInitMessagingFull (CFNotificationCallback callback, void *observer,
			      const CFStringRef **notifications);

#endif /* __ZSIPC_PRIVATE_H */

