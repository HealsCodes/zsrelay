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

#include <stdio.h>
#include <CoreFoundation/CoreFoundation.h>
#include <Foundation/Foundation.h>

#include "zsipc.h"

static void insertPrefBundle(NSString* settingsFile);
static void removePrefBundle(NSString* settingsFile);

int
main (int argc, char **argv)
{
    int ret = 1;
    ZSIPCRef zsIPC = ZSInitMessaging();
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    if (argc >= 2)
    {
	if (strncmp("start", argv[1], 4) == 0)
	{
	    ret = system("/bin/launchctl load -w /Library/LaunchDaemons/org.bitspin.zsrelay.plist");
	}
	else if (strncmp("stop", argv[1], 4) == 0)
	{
	    ZSSendCommand(zsIPC, ZSMsgDoTerminate);
	    ret = system("/bin/launchctl unload -w /Library/LaunchDaemons/org.bitspin.zsrelay.plist");
	}
	else if (strncmp("reconf", argv[1], 6) == 0)
	{
	    ZSSendCommand(zsIPC, ZSMsgDoReConfig);
	}
	else if (strncmp("status", argv[1], 6) == 0)
	{
	    long trafficIn   = 0,
	         trafficOut  = 0,
		 connections = 0;

	    ZSPollTrafficStats(zsIPC, &trafficIn, &trafficOut, &connections);
	    printf("traffic stats\n"
		   "---------------\n"
		   "connections: %d\n"
		   "traffic in : %ld byte\n"
		   "traffic out: %ld byte\n",
		   connections,
		   trafficIn,
		   trafficOut);
	}
	else if(strncmp("install-plugin", argv[1], 14) == 0)
	{
	    insertPrefBundle(@"/Applications/Preferences.app/Settings-iPhone.plist");
	    insertPrefBundle(@"/Applications/Preferences.app/Settings-iPod.plist");
	}
	else if(strncmp("remove-plugin", argv[1], 13) == 0)
	{
	    removePrefBundle(@"/Applications/Preferences.app/Settings-iPhone.plist");
	    removePrefBundle(@"/Applications/Preferences.app/Settings-iPod.plist");
	}
	if (strncmp("ssh-on", argv[1], 7) == 0)
	{
	    ret = system("/bin/launchctl load /Library/LaunchDaemons/com.openssh.sshd.plist");
	}
	else if (strncmp("ssh-off", argv[1], 7) == 0)
	{
	    ret = system("/bin/launchctl unload /Library/LaunchDaemons/com.openssh.sshd.plist");
	}
	ret = 0;
    }
    if (ret != 0)
    {
	fprintf(stderr, "usage: %s [start|stop|status|reconf|install-plugin|remove-plugin|ssh-on|ssh-off]\n", argv[0]);
    }
    ZSDestroy(zsIPC);
    [pool release];
    return ret;
}

/* thanks to scrobbled 2.0 */
void
insertPrefBundle(NSString *settingsFile)
{
    int i;
    NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithContentsOfFile: settingsFile];
    for(i = 0; i < [[settings objectForKey:@"items"] count]; i++)
    {
	NSDictionary *entry = [[settings objectForKey:@"items"] objectAtIndex: i];
	if([[entry objectForKey:@"bundle"] isEqualToString:@"ZSRelaySettings"])
	{
	    printf("Preferences plugin already installed.\n");
	    return;
	}
    }
    printf("Registring preferences plugin.\n");
    [[settings objectForKey:@"items"] insertObject:
	[NSDictionary dictionaryWithObjectsAndKeys:
	@"PSLinkCell", @"cell",
	@"ZSRelaySettings", @"bundle",
	@"iPhoneModem", @"label",
	[NSNumber numberWithInt: 1], @"isController",
	[NSNumber numberWithInt: 1], @"hasIcon",
	nil] atIndex: [[settings objectForKey:@"items"] count] - 1];
    [settings writeToFile:settingsFile atomically:YES];
}

void
removePrefBundle(NSString *settingsFile)
{
    int i;
    NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithContentsOfFile: settingsFile];
    for(i = 0; i < [[settings objectForKey:@"items"] count]; i++)
    {
	NSDictionary *entry = [[settings objectForKey:@"items"] objectAtIndex: i];
	if([[entry objectForKey:@"bundle"] isEqualToString:@"ZSRelaySettings"])
	{
	    printf("Removing preferences plugin.\n");
	    [[settings objectForKey:@"items"] removeObjectAtIndex: i];
	    i--;
	}
    }
    [settings writeToFile:settingsFile atomically:YES];
}

/* vim: ai ft=c ts=8 sts=4 sw=4 fdm=marker noet :
*/

