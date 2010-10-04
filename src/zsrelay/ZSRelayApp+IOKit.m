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

@implementation ZSRelayApp (IOKit)

/* replacement code for 'old' Insomnia method.
 * IOCancelPowerChange had the potential to cause random reboots on iOS >= 4.
 * This method seems to be the safer version anyway..
 */
-(BOOL)setNetworkKeepAlive:(BOOL)isActive
{
    if (isActive == YES)
      {
	if (_ioPMAssertion == -1)
	  {
	    NSLog(@"create ioPMAssertion..");
	    if (IOPMAssertionCreate(kIOPMAssertionTypeNoIdleSleep,
	                            kIOPMAssertionLevelOn, &_ioPMAssertion) != kIOReturnSuccess)
	      return NO;
	  }

	if (_ioPMTimer != nil)
	  {
	    [_ioPMTimer invalidate];
	    [_ioPMTimer release];
	    _ioPMTimer =  [NSTimer scheduledTimerWithTimeInterval:5.0
	                                                   target:self
                                                         selector:@selector(handlePMTimer:)
                                                         userInfo:nil
                                                          repeats:YES];
	    [_ioPMTimer retain];
	  }
	NSLog(@"IOPM active");
	return YES;
      }
    else
      {
	if (_ioPMTimer != nil)
	  {
	    [_ioPMTimer invalidate];
	    [_ioPMTimer release];
	    _ioPMTimer = nil;
	  }

	if (_ioPMAssertion != -1)
	  {
	    NSLog(@"removing ioPMAssertion..");
	    if (IOPMAssertionRelease(_ioPMAssertion) != kIOReturnSuccess)
	      return NO;
	  }
	NSLog(@"IOPM disabled");
	return YES;
      }
    return NO;
}
-(void)handlePMTimer:(NSTimer*)theTimer
{
    static uint32_t ticks = 0;

    theTimer = theTimer; // prevent unused
    NSLog(@"ioPMTimer fired");

    /* the PMAssertion seems to be nullified if the user interacts
     * with her iPhone.. to prevent this, refresh it every 5sec
     */
    if (_ioPMAssertion != -1)
      {
	if (IOPMAssertionRelease(_ioPMAssertion) != kIOReturnSuccess)
	  {
	    NSLog(@"IOPM: failed to release assertion");
	    return;
	  }
	_ioPMAssertion = -1;
	if (IOPMAssertionCreate(kIOPMAssertionTypeNoIdleSleep,
				kIOPMAssertionLevelOn, &_ioPMAssertion) != kIOReturnSuccess)
	  {
	    NSLog(@"IOPM: failed to renew assertion");
	    return;
	  }
      }

    if (ticks % 120 == 0) /* 120 * 5sec */
      {
	iphone_app_check_connection();
	ticks = 0;
      }
}

-(void)synchronousConnectionKeepAlive
{
    NSURL *aURL = nil;
    NSMutableURLRequest *request = nil;
    NSURLConnection *connection = nil;
#if IPHONE_OS_RELEASE >= 2
    if ([self isEdgeUp] == NO)
      {
	_connected = NO;
	if ([self networkKeepAlive] == YES)
	  [self showIcon:ZSStatusZSInsomnia];
	else
	  [self showIcon:ZSStatusZSRelay];
      }
#endif
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
	NSLog(@"synchronous request failed: %@", [error localizedDescription]);
    else
      {
	[self playNotification];
	_connected = YES;

	if ([self networkKeepAlive] == YES)
	  [self showIcon:ZSStatusZSInsomnia];
	else
	  [self showIcon:ZSStatusZSInsomnia];
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
#if IPHONE_OS_RELEASE >= 2
    if ([self isEdgeUp] == NO)
      {
	_connected = NO;
	if ([self networkKeepAlive] == YES)
	  [self showIcon:ZSStatusZSInsomnia];
	else
	  [self showIcon:ZSStatusZSRelay];
      }
#endif
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
      [self showIcon:ZSStatusZSInsomnia];
    else
      [self showIcon:ZSStatusZSRelay];

    [theConnection release];
    _urlConnection = nil;
}

-(void)connectionDidFinishLoading:(NSURLConnection*)theConnection
{

    if (_connected = NO)
      [self playNotification];

    _connected = YES;
    NSLog(@"keep alive successful");

    if ([self networkKeepAlive] == YES)
      [self showIcon:ZSStatusZSInsomnia];
    else
      [self showIcon:ZSStatusZSRelay];

    [theConnection release];
    _urlConnection = nil;

}

@end

