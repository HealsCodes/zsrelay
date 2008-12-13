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

@implementation ZSRelayApp (Settings)

-(BOOL)loadSettings
{
    [[NSUserDefaults standardUserDefaults] addSuiteNamed:@"org.bitspin.zsrelay"];
    NSDictionary *prefs = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"org.bitspin.zsrelay"];

    if (prefs == nil)
    {
	NSLog(@"Storing new user defaults");

	[[NSUserDefaults standardUserDefaults] setObject:@"http://bitspin.org"
						  forKey:@"keepAliveURI"];

	[[NSUserDefaults standardUserDefaults] setBool:YES
						forKey:@"sshOnLaunch"];

	[[NSUserDefaults standardUserDefaults] setBool:NO
						forKey:@"networkKeepAlive"];

	[[NSUserDefaults standardUserDefaults] setBool:YES
						forKey:@"displayStatusIcons"];

	if ([[NSUserDefaults standardUserDefaults] synchronize] == NO)
	{
	    return NO;
	}

	prefs = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"org.bitspin.zsrelay"];
	return prefs != nil;
    }
    else
    {
	NSLog(@"Got user defaults.");
    }
    [[NSUserDefaults standardUserDefaults] setBool:YES
					    forKey:@"zsrelayEnabled"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return YES;
}

-(void)unloadSettings
{
    [[NSUserDefaults standardUserDefaults] setBool:NO
					    forKey:@"zsrelayEnabled"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSString*)keepAliveURI
{
    NSString *theURI = [[NSUserDefaults standardUserDefaults] stringForKey:@"keepAliveURI"];

    if (theURI == nil)
    {
	[[NSUserDefaults standardUserDefaults] setObject:@"http://bitspin.org"
						  forKey:@"keepAliveURI"];
	[[NSUserDefaults standardUserDefaults] synchronize];

	return [self keepAliveURI];
    }

    return theURI;
}

-(BOOL)sshOnLaunch
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"sshOnLaunch"];
}

-(BOOL)networkKeepAlive
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"networkKeepAlive"];
}

-(BOOL)displayStatusIcons
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"displayStatusIcons"];
}

@end

/* vim: ai ft=objc ts=8 sts=4 sw=4 fdm=marker noet :
*/

