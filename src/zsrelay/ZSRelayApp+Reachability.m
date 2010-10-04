/*
   This file is part of zsrelay a srelay port for the iPhone.

   Copyright (C) 2010 Rene Koecher <shirk@bitspin.org>

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
#import <sys/socket.h>
#import <arpa/inet.h>
#import <netinet/in.h>
#import <ifaddrs.h>
#include <netdb.h>

#if IPHONE_OS_RELEASE >= 2
void
iphone_app_check_connection(void)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSLog(@"iphone_app_check_connection..");
    if ([ZSRelayApp sharedApp] != nil)
      {
	if ([[ZSRelayApp sharedApp] isEdgeUp] == NO)
	  {
	    NSLog(@"bringing EDGE up");

	    [[ZSRelayApp sharedApp] synchronousConnectionKeepAlive];
	    NSLog(@"EDGE should be up");
	  }
	else
	  NSLog(@"EDGE _is_ up");
      }
    else
      NSLog(@"sharedApp == nil!");
    [pool release];
}
#endif

@implementation ZSRelayApp (Reachability)

-(BOOL)isEdgeUp
{
#if IPHONE_OS_RELEASE >= 2
    BOOL reachable = NO, needConnection = YES;
    SCNetworkReachabilityFlags flags;

    if (_defaultRouteData == NULL)
      {
	struct sockaddr_in zero;
	bzero(&zero, sizeof(zero));
	zero.sin_len = sizeof(zero);
	zero.sin_family = AF_INET;

	_defaultRouteData = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr*)&zero);
      }

    if (SCNetworkReachabilityGetFlags(_defaultRouteData, &flags) == NO)
      {
	NSLog(@"SCNetworkReachabalityGetFlags returned NO");
	return NO;
      }

    if (!(flags & kSCNetworkReachabilityFlagsReachable)) /* address is not reachable */
      {
	NSLog(@"isEdgeUp: address is not reachable");
	return NO;
      }
    
    if (!(flags & kSCNetworkReachabilityFlagsConnectionRequired) /* we don't need a connection.. */
	|| (flags & kSCNetworkReachabilityFlagsIsWWAN))          /* .. or we are on WWAN */
      {
	if (!(flags & kSCNetworkReachabilityFlagsConnectionRequired))
	  NSLog(@"isEdgeUp: .. no connection required");

	if (flags & kSCNetworkReachabilityFlagsIsWWAN)
	  NSLog(@"isEdgeUp: .. on WWAN");
	
	if (flags & kSCNetworkReachabilityFlagsIsDirect) /* Ad-Hoc ? */
	  {
	    NSLog(@"isEdgeUp: Ad-Hoc?");
	    return NO;
	  }
      }

    NSLog(@"isEdgeUp: Yes");
    return YES;
#else
    return NO;
#endif
}
@end

