/*
   Copyright (C) 2008 Rene Koecher <shirk@bitspin.org>
   All rights reserved.

   You may use and/modify or redistribute this file as long as
   this copyright statement is preserved.

   This code is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*/

#ifndef __LOCALIZED_CONTROLLERS_H
#define __LOCALIZED_CONTROLLERS_H 1

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>

#import <UIKit/UIKit.h>
#import <UIKit/UIHardware.h>

#import <Preferences/PSListController.h>
#import <Preferences/PSListItemsController.h>
#import <Preferences/PSSpecifier.h>

@interface LocalizedListController : PSListController
{
}
-(NSArray *)localizedSpecifiersForSpecifiers:(NSArray *)s;
-(id)navigationTitle;
@end

@interface LocalizedItemsController : PSListItemsController
{
}
-(NSArray *)specifiers;
@end

#endif /* __LOCALIZED_CONTROLLERS_H 1 */

