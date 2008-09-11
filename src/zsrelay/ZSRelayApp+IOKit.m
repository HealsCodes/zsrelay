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

/* my adaption of 'Insomnia'
 * Thanks go out to indiekiduk@gmail.com for discovering the great "feature"
 */

void
powerCallback(void *refCon, io_service_t service, natural_t type, void *argument)
{	
	[(ZSRelayApp*)refCon handlePMMessage:type
	                        withArgument:argument];
}


@implementation ZSRelayApp (IOKit)

-(BOOL)setNetworkKeepAlive:(BOOL)isActive
{
    static IONotificationPortRef notificationPort = NULL;

    if (isActive == YES && notificationPort == NULL)
    {
	root_port = IORegisterForSystemPower(self, &notificationPort,
					     powerCallback, &notifier);
	
	// add the notification port to the application runloop
	CFRunLoopAddSource(CFRunLoopGetCurrent(),
			   IONotificationPortGetRunLoopSource(notificationPort),
			   kCFRunLoopCommonModes);
    }
    else
    {
	if (notificationPort == NULL)
	{
	    return YES;
	}

	CFRunLoopRemoveSource(CFRunLoopGetCurrent(),
			      IONotificationPortGetRunLoopSource(notificationPort),
			      kCFRunLoopCommonModes);
	IODeregisterForSystemPower(&notifier);
	IOServiceClose(root_port);
	IONotificationPortDestroy(notificationPort);
	notificationPort = NULL;
    }
}

- (void)handlePMMessage:(natural_t)type withArgument:(void *) argument
{
    switch (type)
    {
	case kIOMessageSystemWillSleep:
	    IOAllowPowerChange(root_port, (long)argument);  
	    break;

	case kIOMessageCanSystemSleep:
	    IOCancelPowerChange(root_port, (long)argument);
	    break; 

	case kIOMessageSystemHasPoweredOn:
	    break;
    }
}

@end

/* vim: ai ft=objc ts=8 sts=4 sw=4 fdm=marker noet :
*/

