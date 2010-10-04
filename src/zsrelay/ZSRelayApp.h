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

#ifndef ZSRELAY_APP_H
#define ZSRELAY_APP_H

void iphone_app_main(void);

#if defined(__OBJC__)
#if IPHONE_OS_RELEASE >= 2
#import <IOKit/pwr_mgt/IOPMLib.h>
#endif

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>

#import <UIKit/UIKit.h>
#import <UIKit/UIApplication.h>

#if IPHONE_OS_RELEASE == 1
extern void GSEventPlaySoundAtPath(NSString *path);
#else
#   define TARGET_OS_IPHONE 1
#   import <AudioToolbox/AudioServices.h>
#   undef TARGET_OS_IPHONE
#endif

#if IPHONE_OS_RELEASE >= 2
#   define TARGET_OS_IPHONE 1
#   import <SystemConfiguration/SCNetworkReachability.h>
#   undef TARGET_OS_IPHONE
#endif

#include "zsipc-private.h"

enum {
  ZSStatusZSRelay    = 0,
  ZSStatusZSInsomnia = 2,
  ZSStatusIconMax    = 4
};

#define SBA_MessagePortName "SpringBoardAccess"
#define SBA_AddStatusBarImage 1
#define SBA_RemoveStatusBarImage 2

@interface ZSRelayApp : NSObject <UIApplicationDelegate>
//@interface ZSRelayApp : UIApplication
{
#if IPHONE_OS_RELEASE >= 2
    /* IOKit category */
    IOPMAssertionID _ioPMAssertion;
    NSTimer *_ioPMTimer;
#endif

    Boolean _connected;
    NSURLConnection *_urlConnection;

    /* Notify category */
    ZSIPCRef _zsIPC;
#if IPHONE_OS_RELEASE >= 2
    SystemSoundID _connectSound;
#endif
#if IPHONE_OS_RELEASE >= 4
    CFMessagePortRef _sbaMessagePort;
#endif

    /* Reachability category */
#if IPHONE_OS_RELEASE >= 2
    SCNetworkReachabilityRef _defaultRouteData;
#endif
}

+(ZSRelayApp*)sharedApp;

-(void)applicationDidFinishLaunching:(id)unused;
-(void)applicationNeedsReConfigure;
-(void)applicationWillTerminate;
@end

@interface ZSRelayApp (Settings)
-(BOOL)loadSettings;
-(void)unloadSettings;

-(NSString*)keepAliveURI;

-(BOOL)sshOnLaunch;
-(BOOL)networkKeepAlive;
-(BOOL)displayStatusIcons;
@end

@interface ZSRelayApp (IOKit)
-(BOOL)setNetworkKeepAlive:(BOOL)isActive;
-(void)handlePMTimer:(NSTimer*)theTimer;
-(void)connectionKeepAlive;
-(void)synchronousConnectionKeepAlive;
/* NSURLConnection delegate methods */
-(void)connection:(NSURLConnection*)theConnection didFailWithError:(NSError*)error;
-(void)connectionDidFinishLoading:(NSURLConnection*)theConnection;
/* IO-Polling */
-(void)waitForRequestCompletion;
@end

@interface ZSRelayApp (Notify)
-(void)registerNotifications;
-(void)removeNotifications;
-(void)handleNotification:(NSString*)notification;

-(void)playNotification;
#if IPHONE_OS_RELEASE >= 3
-(BOOL)sendSBAMessage:(UInt8)message data:(UInt8*)data len:(CFIndex)len;
#endif
@end

@interface ZSRelayApp (Icons)
-(void)showIcon:(int)iconName;
-(void)showIcon:(int)iconName makeExclusive:(BOOL)exclusive;
-(void)removeIcon:(int)iconName;
-(void)removeAllIcons;
@end

@interface ZSRelayApp (Reachability)
-(BOOL)isEdgeUp;
@end

#endif
#endif

/* vim: ai ts=8 sts=4 sw=4 fdm=marker noet :
*/

