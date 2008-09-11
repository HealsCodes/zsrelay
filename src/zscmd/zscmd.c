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

int
main (int argc, char **argv)
{
    CFStringRef zsTerminate = CFSTR("ZSRelay::applicationWillTerminate");
    CFStringRef zsReConfig  = CFSTR("ZSRelay::applicationNeedsReConfigure");

    CFNotificationCenterRef notifyCenter = NULL;

    if (argc >= 2)
    {
	if (strncmp("start", argv[1], 4) == 0)
	{
	    return system("/bin/launchctl load -w /Library/LaunchDaemons/org.bitspin.zsrelay.plist");
	}
	else if (strncmp("stop", argv[1], 4) == 0)
	{
	    notifyCenter = CFNotificationCenterGetDarwinNotifyCenter();
	    CFNotificationCenterPostNotification(notifyCenter, zsTerminate, NULL, NULL, true);

	    return system("/bin/launchctl unload -w /Library/LaunchDaemons/org.bitspin.zsrelay.plist");
	}
	else if (strncmp("reconf", argv[1], 6) == 0)
	{
	    notifyCenter = CFNotificationCenterGetDarwinNotifyCenter();
	    CFNotificationCenterPostNotification(notifyCenter, zsReConfig, NULL, NULL, true);
	}
    }
    fprintf(stderr, "usage: %s [start|stop|reconf]\n", argv[0]);
    return 1;
}

/* vim: ai ft=c ts=8 sts=4 sw=4 fdm=marker noet :
*/

