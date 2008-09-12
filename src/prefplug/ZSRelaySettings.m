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

#import "ZSRelaySettings.h"
#include <stdio.h>

@implementation LocalizedListController
- (NSArray *)localizedSpecifiersForSpecifiers:(NSArray *)s {

    int i;
    for(i=0; i<[s count]; i++)
    {
	if([[s objectAtIndex: i] name])
	{
	    [[s objectAtIndex: i] setName:[[self bundle] localizedStringForKey:[[s objectAtIndex:i] name]
									 value:[[s objectAtIndex:i] name]
									 table:nil]];
	}
	if([[s objectAtIndex: i] titleDictionary])
	{
	    NSMutableDictionary *newTitles = [[NSMutableDictionary alloc] init];
	    for(NSString *key in [[s objectAtIndex:i] titleDictionary])
	    {
		[newTitles setObject:[[self bundle] localizedStringForKey:[[[s objectAtIndex:i] titleDictionary] objectForKey:key]
								    value:[[[s objectAtIndex:i] titleDictionary] objectForKey:key]
								    table:nil] forKey:key];
	    }
	    [[s objectAtIndex:i] setTitleDictionary:[newTitles autorelease]];
	}
    }
    return s;
}

- (id)navigationTitle {
    return [[self bundle] localizedStringForKey:_title
					  value:_title
					  table:nil];
}
@end

@implementation ZSRelaySettings

-(NSArray*)specifiers
{
    NSArray *s = [self loadSpecifiersFromPlistName:@"ZSRelay"
					    target:self];

    s = [self localizedSpecifiersForSpecifiers:s];
    return s;
}

-(void)triggerReConfig
{
    FILE *child_fd = NULL;

    NSLog(@"triggerReConfig");
    child_fd = popen("/usr/sbin/zscmd reconf", "r");
    if (child_fd != NULL)
    {
	fclose(child_fd);
    }
}

-(BOOL)getDaemonEnabled;
{
    return NO;
}

-(void)setDaemonEnabled:(id)value specifier:(id)specifier
{
    FILE *child_fd = NULL;

    [self setPreferenceValue:value specifier:specifier];
    [[NSUserDefaults standardUserDefaults] synchronize];

    if (value == kCFBooleanTrue)
    {
	NSLog(@"enabling zsrelay...");
	child_fd = popen("/usr/sbin/zscmd start", "r");
	if (child_fd != NULL)
	{
	    fclose(child_fd);
	}
    }
    else
    {
	NSLog(@"disabling zsrelay...");
	child_fd = popen("/usr/sbin/zscmd stop", "r");
	if (child_fd != NULL)
	{
	    fclose(child_fd);
	}
    }
}

-(void)setPrefVal:(id)value specifier:(id)specifier
{
    FILE *child_fd = NULL;

    [self setPreferenceValue:value specifier:specifier];
    [[NSUserDefaults standardUserDefaults] synchronize];

//    NSLog(@"set '%@' %s", specifier, value == kCFBooleanTrue ? "on":"off");
    [self triggerReConfig];
}

@end

/* vim: ai ft=objc ts=8 sts=4 sw=4 fdm=marker noet :
*/

