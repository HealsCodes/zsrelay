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

/* vim: ai ts=8 sts=4 sw=4 fdm=marker noet :
*/
#ifndef ZSRELAY_APP_H
#define ZSRELAY_APP_H

void iphone_app_main(void);

#if defined(__OBJC__)
#import <IOKit/pwr_mgt/IOPMLib.h>
#import <IOKit/IOMessage.h>

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>

#import <UIKit/UIKit.h>

@interface ZSRelayApp : UIApplication
{
    /* IOKit category */
    io_connect_t root_port;
    io_object_t  notifier;

    /* Notify category */
    CFNotificationCenterRef _notifyCenter;
}

+(ZSRelayApp*)sharedApp:(ZSRelayApp*)newInstance;

-(void)applicationDidFinishLaunching:(id)unused;
-(void)applicationWillTerminate;
@end

@interface ZSRelayApp (Settings)
-(BOOL)loadSettings;
-(BOOL)patchDNS;
-(BOOL)networkKeepAlive;
-(BOOL)displayStatusIcons;
/* additions for iPhoneModem support */
-(BOOL)iPhoneModem;
-(BOOL)iPhoneModemSupervisor;
@end

@interface ZSRelayApp (IOKit)
-(BOOL)setNetworkKeepAlive:(BOOL)isActive;
-(void)handlePMMessage:(natural_t)type withArgument:(void *)argument;
@end

@interface ZSRelayApp (Notify)
-(void)registerNotifications;
-(void)removeNotifications;
-(void)handleNotification:(NSString*)notification;
@end

@interface ZSRelayApp (Icons)
-(void)showIcon:(NSString*)iconName;
-(void)showIcon:(NSString*)iconName makeExclusive:(BOOL)exclusive;
-(void)removeIcon:(NSString*)iconName;
-(void)removeAllIcons;
@end

#endif
#endif

