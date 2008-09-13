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

#include <unistd.h>
#include <string.h>

#include "zsipc-private.h"

const CFStringRef ZSMsgDoTerminate  = CFSTR("org.bitspin.zsrelay.ipc.exec-term");
const CFStringRef ZSMsgDoReConfig   = CFSTR("org.bitspin.zsrelay.ipc.exec-conf");

const CFStringRef ZSMsgDoTrafficStats  = CFSTR("org.bitspin.zsrelay.ipc.exec-stats");

static const CFStringRef *ZSMsgList[] = {
    NULL
};

struct _ZSIPCRef
{
    CFNotificationCenterRef notifyRef;

    long trafficIn;
    long trafficOut;
    long connections;

    void *observer;
};

ZSIPCRef
ZSInitMessaging (void)
{
    return ZSInitMessagingFull(NULL, NULL, NULL);
}

ZSIPCRef
ZSInitMessagingFull (CFNotificationCallback callback, void *observer, const CFStringRef **notifications)
{
    int i;
    struct _ZSIPCRef *ipcRef = NULL;

    ipcRef = (struct _ZSIPCRef*)malloc(sizeof(struct _ZSIPCRef));

    if (ipcRef == NULL)
    {
	return NULL;
    }

    memset(ipcRef, 0, sizeof(struct _ZSIPCRef));
    ipcRef->notifyRef = CFNotificationCenterGetDarwinNotifyCenter();
    ipcRef->observer  = (observer == NULL) ? ipcRef : observer;

    if (callback != NULL && notifications != NULL)
    {
	for (i = 0; notifications[i] != NULL; i++)
	{
	    CFNotificationCenterAddObserver(ipcRef->notifyRef,
					    ipcRef->observer,
					    callback,
					    *notifications[i],
					    NULL,
					    CFNotificationSuspensionBehaviorDeliverImmediately);
	}
    }
    return ipcRef;
}

void
ZSDestroy (ZSIPCRef ipcRef)
{
    if (ipcRef == NULL)
    {
	return;
    }

    CFNotificationCenterRemoveEveryObserver(ipcRef->notifyRef, ipcRef->observer);
    free(ipcRef);
}

void
ZSSendCommand (ZSIPCRef ipcRef, CFStringRef ipcCmd)
{
    if (ipcRef == NULL)
    {
	return;
    }

    CFNotificationCenterPostNotification(ipcRef->notifyRef,
					 ipcCmd,
					 NULL,
					 NULL,
					 true);
}

void
ZSPollTrafficStats (ZSIPCRef ipcRef, long *trafficIn, long *trafficOut, long *connections)
{
    FILE *statusFile = NULL;
    ipcRef->trafficIn   = 0;
    ipcRef->trafficOut  = 0;
    ipcRef->connections = 0;

    ZSSendCommand(ipcRef, ZSMsgDoTrafficStats);
    sleep(1);

    statusFile = fopen(ZSURLStatus, "r");
    if (statusFile != NULL)
    {
	fscanf(statusFile, " %ld ; %ld ; %ld ",
	       &ipcRef->trafficIn,
	       &ipcRef->trafficOut,
	       &ipcRef->connections);

	fclose(statusFile);
    }

    if (trafficIn != NULL)
    {
	*trafficIn = ipcRef->trafficIn;
    }
    if (trafficOut != NULL)
    {
	*trafficOut = ipcRef->trafficOut;
    }
    if (connections != NULL)
    {
	*connections = ipcRef->connections;
    }
}

/* vim: ai ft=c ts=8 sts=4 sw=4 fdm=marker noet :
*/

