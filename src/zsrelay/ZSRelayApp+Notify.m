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

#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#import "ZSRelayApp.h"

static void
iphone_app_handle_notify (CFNotificationCenterRef center, void *observer,
			  CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    if (observer != NULL)
    {
	[(ZSRelayApp*)observer handleNotification:(NSString*)name];
    }
}

@implementation ZSRelayApp (Notify)
-(void)registerNotifications
{
    const CFStringRef *ZSMsgList[] = {
	&ZSMsgDoTerminate,
	&ZSMsgDoReConfig,
	&ZSMsgDoTrafficStats,

	NULL
    };

    _zsIPC = ZSInitMessagingFull(iphone_app_handle_notify, self, ZSMsgList);
}

-(void)removeNotifications
{
    ZSDestroy(_zsIPC);
}

-(void)handleNotification:(NSString*)notification
{
    if ([notification compare:(NSString*)ZSMsgDoTerminate] == NSOrderedSame)
    {
	NSLog(@"handleNotification: applicationWillTerminate");
	[self applicationWillTerminate];
    }
    else if ([notification compare:(NSString*)ZSMsgDoReConfig] == NSOrderedSame)
    {
	NSLog(@"handleNotification: applicationNeedsReConfigure");
	[self applicationNeedsReConfigure];
    }
    else if ([notification compare:(NSString*)ZSMsgDoTrafficStats] == NSOrderedSame)
    {
	FILE *statusFile = NULL;

	long trafficIn = 0;
	long trafficOut = 0;
	long connections = 0;

	NSLog(@"handleNotification: pollTrafficStats");
	accumulate_traffic(&trafficIn, &trafficOut, &connections);

	statusFile = fopen(ZSURLStatus, "w");
	if (statusFile != NULL)
	{
	    fprintf(statusFile, "%ld;%ld;%ld\n",
		    trafficIn,
		    trafficOut,
		    connections);
	    fclose(statusFile);
	}
    }
    else
    {
	NSLog(@"handleNotification: ignoring '%@'", notification);
    }
}
@end

/* vim: ai ft=objc ts=8 sts=4 sw=4 fdm=marker noet :
*/

