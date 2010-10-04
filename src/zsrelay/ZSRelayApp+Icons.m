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

#import "ZSRelayApp.h"

static const char *_statusIconNames[] = {
	"ZSRelay",
	"ZSRelayNOP",
	"ZSRelayInsomnia",
	"ZSRelayInsomniaNOP"
};

@implementation ZSRelayApp (Icons)

-(void)showIcon:(int)iconName
{
    [self showIcon:iconName
     makeExclusive:YES];
}

-(void)showIcon:(int)iconName makeExclusive:(BOOL)exclusive
{
    NSString *name = nil;

    if ([self displayStatusIcons] == NO)
	return;

    if (_connected == NO && iconName % 2 != 0)
	iconName++;

    if (iconName > ZSStatusIconMax)
      return;

    if (exclusive == YES)
      [self removeAllIcons];

    [self sendSBAMessage:SBA_AddStatusBarImage
                    data:(uint8_t*)_statusIconNames[iconName]
                     len:strlen(_statusIconNames[iconName])];
}

-(void)removeIcon:(int)iconName
{
    NSString *name = nil;
    if ([self displayStatusIcons] == NO)
	return;

    if (_connected == NO && iconName % 2 != 0)
      iconName++;

    if (iconName > ZSStatusIconMax)
      return;

    [self sendSBAMessage:SBA_RemoveStatusBarImage
                    data:(uint8_t*)_statusIconNames[iconName]
                     len:strlen(_statusIconNames[iconName])];
}

-(void)removeAllIcons
{
    int i = 0;
    NSString *name = nil;

    for (i = 0; i < ZSStatusIconMax; i++)
      {
	[self sendSBAMessage:SBA_RemoveStatusBarImage
                        data:(uint8_t*)_statusIconNames[i]
                         len:strlen(_statusIconNames[i])];

	usleep(1000);
      }
}
@end

