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
#include <sched.h>

void
iphone_app_check_connection(void)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSLog(@"iphone_app_check_connection..");
    if ([ZSRelayApp sharedApp] != nil)
    {
	if ([[NetworkController sharedInstance] isEdgeUp] == NO)
	{
	    NSLog(@"bringing EDGE up");

	    [[ZSRelayApp sharedApp] synchronousConnectionKeepAlive];
	    NSLog(@"EDGE should be up");
	}
	else
	{
	    NSLog(@"EDGE _is_ up");
	}
    }
    else
    {
	NSLog(@"sharedApp == nil!");
    }
    [pool release];
}

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

	return YES;
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

	return YES;
    }

    return NO;
}

- (void)handlePMMessage:(natural_t)type withArgument:(void *) argument
{
    static int messagesSoFar = 0;

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

    messagesSoFar++;

    if (messagesSoFar == 20) /* one message each 30 seconds */
    {
	[self connectionKeepAlive];
	messagesSoFar = 0;
    }
}

-(void)synchronousConnectionKeepAlive
{
    NSURL *aURL = nil;
    NSMutableURLRequest *request = nil;
    NSURLConnection *connection = nil;

    if ([[NetworkController sharedInstance] isEdgeUp] == NO)
    {
	_connected = NO;
	if ([self networkKeepAlive] == YES)
	{
	    [self showIcon:@"ZSRelayInsomnia"];
	}
	else
	{
	    [self showIcon:@"ZSRelay"];
	}
    }

    NSLog(@"Sending synchronous keep alive to %@", [self keepAliveURI]);

    aURL     = [NSURL URLWithString:[self keepAliveURI]];
    request  = [NSMutableURLRequest requestWithURL:aURL
				       cachePolicy:NSURLRequestReloadIgnoringCacheData
				   timeoutInterval:30.0];
    [request setHTTPMethod:@"HEAD"];

    _urlConnection = [NSURLConnection connectionWithRequest:request
						   delegate:self];

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSData *data            = nil;
    NSError *error          = nil;
    NSURLResponse *response = nil;

    data = [NSURLConnection sendSynchronousRequest:request
				 returningResponse:&response
					     error:&error];

    if (error != nil)
    {	
	NSLog(@"synchronous request failed: %@", [error localizedDescription]);
    }
    else
    {
	[self playNotification];
	_connected = YES;

	if ([self networkKeepAlive] == YES)
	{
	    [self showIcon:@"ZSRelayInsomnia"];
	}
	else
	{
	    [self showIcon:@"ZSRelay"];
	}
    }

    [pool release];
}

-(void)connectionKeepAlive
{
    NSURL *aURL = nil;
    NSMutableURLRequest *request = nil;

    if (_urlConnection != nil)
    {
	NSLog(@"Ignoring keep alive - request pending");
	return;
    }

    if ([[NetworkController sharedInstance] isEdgeUp] == NO)
    {
	_connected = NO;
	if ([self networkKeepAlive] == YES)
	{
	    [self showIcon:@"ZSRelayInsomnia"];
	}
	else
	{
	    [self showIcon:@"ZSRelay"];
	}
    }

    NSLog(@"Sending keep alive to %@", [self keepAliveURI]);

    aURL     = [NSURL URLWithString:[self keepAliveURI]];
    request  = [NSMutableURLRequest requestWithURL:aURL
				       cachePolicy:NSURLRequestReloadIgnoringCacheData
				   timeoutInterval:30.0];

    [request setHTTPMethod:@"HEAD"];
    _urlConnection = [NSURLConnection connectionWithRequest:request
						   delegate:self];
}

-(void)connection:(NSURLConnection*)theConnection didFailWithError:(NSError*)error
{
    _connected = NO;
    NSLog(@"keep alive failed with error: %@",
	    [error localizedDescription]);

    if ([self networkKeepAlive] == YES)
    {
	[self showIcon:@"ZSRelayInsomnia"];
    }
    else
    {
	[self showIcon:@"ZSRelay"];
    }

    [theConnection release];
    _urlConnection = nil;
}

-(void)connectionDidFinishLoading:(NSURLConnection*)theConnection
{

    if (_connected = NO)
    {
        [self playNotification];
    }
    _connected = YES;
    NSLog(@"keep alive successful");

    if ([self networkKeepAlive] == YES)
    {
	[self showIcon:@"ZSRelayInsomnia"];
    }
    else
    {
	[self showIcon:@"ZSRelay"];
    }

    [theConnection release];
    _urlConnection = nil;

}

@end

/* vim: ai ft=objc ts=8 sts=4 sw=4 fdm=marker noet :
*/

