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

#if HAVE_CONFIG_H
#include <config.h>
#endif

#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <Foundation/NSBundle.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIProgressHUD.h>

typedef void* Apple80211Ref;

@interface ZSLauncher: UIApplication
{
    UIWindow *_window;
    UIProgressHUD *_progress;
    UIView *_mainView;

    /* Apple80211 */
    Apple80211Ref _handle;
    NSDictionary *_bssData;
    NSDictionary *_netInfo;
}

-(void)applicationDidFinishLaunching:(NSNotification*)aNotification;
-(void)applicationWillTerminate;
-(void)applicationDidResume;
-(void)showStatus:(NSString*)aString;
@end

@interface ZSLauncher (Apple80211)
-(BOOL)bringUpWiFi;
-(BOOL)isNetworkAvailable;
-(BOOL)bindToNetwork;
-(BOOL)finalizeWiFi;
@end

/* vim: ai ts=8 sts=4 sw=4 fdm=marker noet :
*/

