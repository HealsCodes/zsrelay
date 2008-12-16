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
#import <Preferences/PSSpecifier.h>

#include <stdio.h>
#include <glob.h>

#include "zsipc.h"

#if IPHONE_OS_RELEASE >= 2
#define PREFS_BUNDLE_PATH "/System/Library/PreferenceBundles/ZSRelaySettings.bundle/plugins/*.bundle"

/* Provide the fast enumeration prototypes */
typedef struct {
   unsigned long state;
   id *itemsPtr;
   unsigned long *mutationsPtr;
   unsigned long extra[5];
} NSFastEnumerationState;

@interface NSArray (FastEnumeration)
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState*)state
                                 objects:(id*)stackbuf count:(NSUInteger)len;
@end

/* Provide the informal interface plugin bundles may implement */
@interface NSObject (ZSPrefPlugin)
+(NSString*)entryName;
+(NSString*)insertAfter;
+(NSArray*)disableMenuItems;
@end
#endif

@implementation LocalizedListController
-(NSArray*)localizedSpecifiersForSpecifiers:(NSArray*)s
{
  int i;
  for(i=0; i<[s count]; i++)
    {
      if([[s objectAtIndex: i] name])
	{
	  [[s objectAtIndex: i] setName:[[self bundle]
	          localizedStringForKey:[[s objectAtIndex:i] name]
	                          value:[[s objectAtIndex:i] name]
	                          table:nil]];
	}
      if([[s objectAtIndex: i] titleDictionary])
	{
	  NSMutableDictionary *newTitles = [[NSMutableDictionary alloc] init];
	  for(NSString *key in [[s objectAtIndex:i] titleDictionary])
	    {
	      [newTitles setObject:[[self bundle]
		localizedStringForKey:[[[s objectAtIndex:i] titleDictionary] objectForKey:key]
		                value:[[[s objectAtIndex:i] titleDictionary] objectForKey:key]
		                table:nil] forKey:key];
	    }
	  [[s objectAtIndex:i] setTitleDictionary:[newTitles autorelease]];
	}
    }
  return s;
}

-(id)navigationTitle
{
  return [[self bundle] localizedStringForKey:_title
                                        value:_title
                                        table:nil];
}

#if IPHONE_OS_RELEASE >= 2
-(NSArray*)updateSpecifiers:(NSArray*)mySpecifiers withBundles:(NSArray*)bundleList
{
#define PSGROUP_CELLID    0
#define PSLINKLIST_CELLID 1

    NSMutableArray *s = [mySpecifiers mutableCopy];

    /* first walk - insert plugin bundles into desired locations */
    for (NSBundle *bundle in bundleList)
      {
	int offset = -1;
	NSString *name = nil;
	PSSpecifier *specifier = nil;

	Class bundleClass = [bundle principalClass];

	if ([bundleClass respondsToSelector:@selector(entryName)])
	  name = [NSString stringWithString:[bundleClass entryName]];
	else
	  name = [NSString stringWithFormat:@"%@", [bundle principalClass]];

	if ([bundleClass respondsToSelector:@selector(insertAfter)])
	  {
	    BOOL match = NO;
	    offset = [s count] -1;

	    while (offset >= 0)
	      {
		PSSpecifier *sp = [s objectAtIndex:offset];

		if ([[sp propertyForKey:@"id"] isEqualToString:[bundleClass insertAfter]])
		  {
		    match = YES;
		    break;
		  }

		offset--;
	      }

	    if (match)
	      offset++;
	  }

	if (offset == -1)
	  offset = [s count] - 2;

	specifier = [PSSpecifier preferenceSpecifierNamed:name
	                                           target:nil
	                                              set:nil
	                                              get:nil
	                                           detail:[bundle principalClass]
	                                             cell:PSLINKLIST_CELLID
	                                             edit:nil];
	[s insertObject:specifier
		atIndex:offset];

    }

    /* second walk - now we disable menu items (if needed) */
    for (NSBundle *bundle in bundleList)
      {
	Class bundleClass = [bundle principalClass];

	if ([bundleClass respondsToSelector:@selector(disableMenuItems)])
	  {
	    NSArray *hideRequests = [bundleClass disableMenuItems];

	    for (NSString *itemId in hideRequests)
	      {
		int i = 0;
		for (; i < [s count]; i++)
		  {
		    if ([[[s objectAtIndex:i] propertyForKey:@"id"] isEqualToString:itemId])
		      {
			[s removeObjectAtIndex:i];
			i = [s count] + 1;
			break;
		      }
		  }
	      }
	  }
      }

    return s;
}

@end
#endif

@implementation ZSRelaySettings

-(id)initForContentSize:(struct CGSize)size 
{
    self = [super initForContentSize:size];
    _zsIPC = ZSInitMessaging();
    _cachedSpecifiers = nil;

#if IPHONE_OS_RELEASE >= 2
    glob_t bundles;
    _pluginBundles = [[NSMutableArray alloc] initWithCapacity:10];

    if (glob(PREFS_BUNDLE_PATH, 0, NULL, &bundles) == 0)
      {
//	freopen("/tmp/prefs.log", "a", stderr);

	NSLog(@"path_c: %d", bundles.gl_pathc);
	int i = 0;

	for (; i < bundles.gl_pathc; i++)
	  {
	    NSBundle *bundle = nil;
	    NSString *path = [NSString stringWithCString:bundles.gl_pathv[i]
	                                        encoding:NSASCIIStringEncoding];

	    NSLog(@"loading bundle: %@", path);
	    bundle = [NSBundle bundleWithPath:path];

	    if (bundle == nil)
	      {
		NSLog(@"failed to load bundle %@", path);
		continue;
	      }

	    if ([bundle principalClass])
	      {
		NSLog(@".. pricipalClass: %@", [bundle principalClass]);
		[_pluginBundles addObject:bundle];
	      }
	    else
	      NSLog(@".. bundle defines no principalClass!?");
	  }

	globfree(&bundles);
      }
#endif

    return self;
}

-(void)dealloc
{
    if (_cachedSpecifiers != nil)
      [_cachedSpecifiers release];

#if IPHONE_OS_RELEASE >= 2
    if (_pluginBundles != nil)
      [_pluginBundles release];
#endif

    ZSDestroy(_zsIPC);
    [super dealloc];
}

-(NSArray*)specifiers
{
    if (_cachedSpecifiers != nil)
      return _cachedSpecifiers;

    NSArray *s = [self loadSpecifiersFromPlistName:@"ZSRelay"
                                            target:self];
    s = [self localizedSpecifiersForSpecifiers:s];

    _cachedSpecifiers = [self updateSpecifiers:s
		                   withBundles:_pluginBundles];

    [_cachedSpecifiers retain];
    return _cachedSpecifiers;
}

-(void)triggerReConfig
{
    FILE *child_fd = NULL;

    NSLog(@"triggerReConfig");
    ZSSendCommand(_zsIPC, ZSMsgDoReConfig);
}

-(void)setDaemonEnabled:(id)value specifier:(id)specifier
{
    FILE *child_fd = NULL;

    [self setPreferenceValue:value
                   specifier:specifier];

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
    [self setPreferenceValue:value
                   specifier:specifier];

    [[NSUserDefaults standardUserDefaults] synchronize];

    [self triggerReConfig];
}

-(void)supportButton:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://bitspin.org/support.html"]];
}
@end

@implementation AdvancedController

-(id)initForContentSize:(struct CGSize)size 
{
    self = [super initForContentSize:size];
    _zsIPC = ZSInitMessaging();

    [NSTimer scheduledTimerWithTimeInterval:5.0
                                     target:self
                                   selector:@selector(pollTrafficStats:)
                                   userInfo:nil
                                   repeats:YES];
    return self;
}

-(void)dealloc
{
    unlink(ZSURLStatus);
    ZSDestroy(_zsIPC);
    [super dealloc];
}

-(NSArray*)specifiers
{
    NSArray *s = [self loadSpecifiersFromPlistName:@"advanced"
                                            target:self];

    s = [self localizedSpecifiersForSpecifiers:s];
    return s;
}

-(void)triggerReConfig
{
    FILE *child_fd = NULL;

    NSLog(@"triggerReConfig");
    ZSSendCommand(_zsIPC, ZSMsgDoReConfig);
}

-(void)pollTrafficStats:(NSTimer*)aTimer
{
    ZSPollTrafficStats(_zsIPC, &_trafficIn, &_trafficOut, &_connections);
    [self reload];
}

-(NSString*)getTrafficIn:(id)sender
{
    return [self getFormatedTraffic:_trafficIn];
}

-(NSString*)getTrafficOut:(id)sender
{
    return [self getFormatedTraffic:_trafficOut];
}

-(NSString*)getFormatedTraffic:(long)trafficStat
{
    char suffix[3];
    double tOut = 0.0;

    if (trafficStat >= (1024*1024*1024))
      {
	strcpy(suffix, "Gb");
	tOut = trafficStat / (1024.0*1024.0*1024.0);
      }
    else if (trafficStat >= (1024*1024))
      {
	strcpy(suffix, "Mb");
	tOut = trafficStat / (1024.0*1024.0);
      }
    else if (trafficStat >= 1024)
      {
	strcpy(suffix, "Kb");
	tOut = trafficStat / 1024.0;
      }
    else
      {
	strcpy(suffix, "b");
	tOut = trafficStat;
      }

    return [NSString stringWithFormat:@"%.1f%s", tOut, suffix];
}

-(NSString*)getConnections:(id)sender
{
    return [NSString stringWithFormat:@"%ld", _connections];
}
-(void)prefplugButton:(id)sender
{
    FILE *child_fd = NULL;

    NSLog(@"enabling zsrelay...");
    child_fd = popen("/usr/sbin/zscmd install-plugin", "r");
    if (child_fd != NULL)
      {
	fclose(child_fd);
      }
}
@end

