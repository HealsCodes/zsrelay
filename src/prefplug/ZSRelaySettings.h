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

#ifndef __ZSRELAY_SETTINGS_H
#define __ZSRELAY_SETTINGS_H 1

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>

#import <UIKit/UIKit.h>
#import <UIKit/UIHardware.h>

#import <Preferences/PSListController.h>
#import <Preferences/PSListItemsController.h>
#import <Preferences/PSSpecifier.h>

#include "zsipc.h"

@interface LocalizedListController : PSListController
{
}
-(NSArray *)localizedSpecifiersForSpecifiers:(NSArray *)s;
-(id)navigationTitle;
-(NSArray*)updateSpecifiers:(NSArray*)mySpecifiers withBundles:(NSArray*)bundleList;
@end

@interface ZSRelaySettings : LocalizedListController
{
    ZSIPCRef _zsIPC;
#if IPHONE_OS_RELEASE >= 2
    NSMutableArray *_pluginBundles;
#endif
    NSArray *_cachedSpecifiers;
}

-(id)initForContentSize:(struct CGSize)size;
-(void)dealloc;

-(NSArray*)specifiers;

-(void)triggerReConfig;

-(void)setDaemonEnabled:(id)value specifier:(id)specifier;
-(void)setPrefVal:(id)value specifier:(id)specifier;

-(void)supportButton:(id)sender;
@end

@interface AdvancedController : LocalizedListController
{
    long _trafficIn;
    long _trafficOut;
    long _connections;

    ZSIPCRef _zsIPC;
}
-(id)initForContentSize:(struct CGSize)size;
-(void)dealloc;

-(NSArray *)specifiers;

-(void)pollTrafficStats:(NSTimer*)aTimer;
-(NSString*)getTrafficIn:(id)sender;
-(NSString*)getTrafficOut:(id)sender;
-(NSString*)getConnections:(id)sender;

-(NSString*)getFormatedTraffic:(long)trafficStat;
@end

#endif /* __ZSRELAY_SETTINGS_H 1 */

/* vim: ai ts=8 sts=4 sw=4 fdm=marker noet :
*/

