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
#include <sys/types.h>
#include <sys/stat.h>
#include <glob.h>

#include <string.h>
#include <errno.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netinet/in.h>

#include "zsipc.h"


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
  return [[self bundle] localizedStringForKey:[self title]
                                        value:[self title]
                                        table:nil];
}
@end

@implementation ZSRelaySettings

-(id)initForContentSize:(struct CGSize)size 
{
    struct stat stats;
    if (stat("/tmp/ZSRelaySettings.log", &stats) == 0)
      {
	freopen("/tmp/ZSRelaySettings.log", "a", stderr);
      }

    self = [super initForContentSize:size];
    _zsIPC = ZSInitMessaging();
    _specifiers = nil;

    return self;
}

-(void)dealloc
{
    ZSDestroy(_zsIPC);
    [super dealloc];
}

-(NSArray*)specifiers
{
    if (_specifiers != nil)
      return _specifiers;

    NSMutableArray *s = [self loadSpecifiersFromPlistName:@"ZSRelay"
                                                   target:self];
    s = [NSMutableArray arrayWithArray:[self localizedSpecifiersForSpecifiers:s]];

    _specifiers = (NSArray*)s;
    [_specifiers retain];
    return _specifiers;
}

-(void)triggerReConfig
{
    FILE *child_fd = NULL;

    NSLog(@"triggerReConfig");
    ZSSendCommand(_zsIPC, ZSMsgDoReConfig);
}

-(id)getDaemonEnabled:(id)specifier
{
    /* try to connect to zsrelay */
    int sockfd;
    struct sockaddr_in saddr;

    sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd < 0)
      {
	NSLog(@"socket error: %s", strerror(errno));
	return [NSNumber numberWithBool:NO];
      }

    bzero(&saddr, sizeof(saddr));
    saddr.sin_family = AF_INET;
    saddr.sin_port   = htons(1080);
    saddr.sin_addr.s_addr = inet_addr("127.0.0.1");

    if (connect(sockfd, (struct sockaddr*)&saddr, sizeof(saddr)) == 0)
      {
	NSLog(@"return status YES");
	close(sockfd);
	return [NSNumber numberWithBool:YES];
      }

    NSLog(@"return status NO");
    close(sockfd);
    return [NSNumber numberWithBool:NO];
}

-(void)setDaemonEnabled:(id)value specifier:(id)specifier
{
    [self setPreferenceValue:value
                   specifier:specifier];

    [[NSUserDefaults standardUserDefaults] synchronize];

    if (value == kCFBooleanTrue)
      {
	NSLog(@"enabling zsrelay... [%d]",
	      notify_post("org.bitspin.zsrelay.start"));
      }
    else
      {
	NSLog(@"disabling zsrelay... [%d]",
	      notify_post("org.bitspin.zsrelay.stop"));
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
    _specifiers = nil;
    _refreshTimer = nil;

    return self;
}

-(void)dealloc
{
    if (_refreshTimer != nil)
      {
	[_refreshTimer invalidate];
	[_refreshTimer release];
	_refreshTimer = nil;
      }
    unlink(ZSURLStatus);
    ZSDestroy(_zsIPC);
    [super dealloc];
}

-(NSArray*)specifiers
{
    if (_specifiers != nil)
      return _specifiers;

    NSArray *s = [self loadSpecifiersFromPlistName:@"advanced"
                                            target:self];

    _specifiers = [[self localizedSpecifiersForSpecifiers:s] retain];
    return _specifiers;
}

-(void)viewDidAppear:(BOOL)animated
{
    NSLog(@"viewDidAppear");

    if (_refreshTimer == nil)
      {
	NSLog(@"start refreshTimer");
	_refreshTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
	                                                 target:self
	                                               selector:@selector(pollTrafficStats:)
	                                               userInfo:nil
	                                                repeats:YES];
	[_refreshTimer retain];
      }
}

-(void)viewDidDisappear:(BOOL)animated
{
    NSLog(@"viewDidDisappear");
    if (_refreshTimer != nil)
      {
	NSLog(@"stop refreshTimer");
	[_refreshTimer invalidate];
	[_refreshTimer release];
	_refreshTimer = nil;
      }
}

-(void)viewDidBecomeVisible
{
    /* iOS < 4 will get here */
    if (_refreshTimer == nil)
      {
	NSLog(@"viewDidBecomeVisible [legacy]");
	[self viewDidAppear:NO];
      }
}

-(void)suspend
{
    /* iOS < 4 will get here */
    if (_refreshTimer != nil)
      {
	NSLog(@"suspend [legacy]");
	[self viewDidDisappear:NO];
      }
}

-(void)triggerReConfig
{
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
    /*
    FILE *child_fd = NULL;

    NSLog(@"enabling zsrelay...");
    child_fd = popen("/usr/sbin/zscmd install-plugin", "r");
    if (child_fd != NULL)
      {
	fclose(child_fd);
      }
      */
}
@end

