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

#ifndef ZSRELAY_SETTINGS_H
#define ZSRELAY_SETTINGS_H

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>

#import <UIKit/UIKit.h>
#import <UIKit/UIHardware.h>

#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface LocalizedListController : PSListController
{
}
-(NSArray *)localizedSpecifiersForSpecifiers:(NSArray *)s;
-(id)navigationTitle;
@end

@interface ZSRelaySettings : LocalizedListController
{
}
-(NSArray*)specifiers;
-(void)triggerReConfig;

-(BOOL)getDaemonEnabled;
-(void)setDaemonEnabled:(id)value specifier:(id)specifier;
-(void)setPrefVal:(id)value specifier:(id)specifier;

@end
#endif

/* vim: ai ts=8 sts=4 sw=4 fdm=marker noet :
*/

