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

#import "Demo.h"
#import <Preferences/PSSpecifier.h>

#include <stdio.h>

@implementation Demo
/*
+(NSString*)singleEntry
{
    return @"Demo Plugin";
}
*/

+(NSArray*)entryList
{
    return [NSArray arrayWithObjects:
		[NSDictionary dictionaryWithObjectsAndKeys:
		    @"Demo entry1", @"name",
		    [Demo class]  , @"class",
		    nil, nil],
		[NSDictionary dictionaryWithObjectsAndKeys:
		    @"Demo entry2" , @"name",
		    [DemoSub class], @"class",
		    nil, nil],
		nil];
}

+(NSString*)insertAfter
{
    return @"ID_SSH_QUICKLAUNCH";
}

+(NSArray*)disableMenuItems
{
    return [NSArray arrayWithObjects:@"ID_ENABLE_INSOMNIA",
				     @"ID_SSH_QUICKLAUNCH",
				     nil];
}

-(id)initForContentSize:(struct CGSize)size 
{
    self = [super initForContentSize:size];
    return self;
}

-(void)dealloc
{
    [super dealloc];
}

-(NSArray*)specifiers
{
    NSArray *s = [self loadSpecifiersFromPlistName:@"Demo"
                                            target:self];

    s = [self localizedSpecifiersForSpecifiers:s];
    return s;
}

-(void)demoButton:(id)sender
{
    NSLog(@"demo button pressed!...");
}

@end

@implementation DemoSub

-(id)initForContentSize:(struct CGSize)size 
{
    self = [super initForContentSize:size];
    return self;
}

-(void)dealloc
{
    [super dealloc];
}

-(NSArray*)specifiers
{
    NSArray *s = [self loadSpecifiersFromPlistName:@"DemoSub"
                                            target:self];

    s = [self localizedSpecifiersForSpecifiers:s];
    return s;
}

-(void)demoButton:(id)sender
{
    NSLog(@"demo button pressed!...");
}

@end

