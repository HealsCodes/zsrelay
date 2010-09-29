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
	"org.bitspin.zsrelay.icons.ZSRelay",
	"org.bitspin.zsrelay.icons.ZSRelayNOP",
	"org.bitspin.zsrelay.icons.ZSRelayInsomnia",
	"org.bitspin.zsrelay.icons.ZSRelayInsomniaNOP"
};

@implementation ZSRelayApp (Icons)

-(void)showIcon:(int)iconName
{
    [self showIcon:iconName
     makeExclusive:YES];
}

-(void)showIcon:(int)iconName makeExclusive:(BOOL)exclusive
{
    char name_buff[128];

    if ([self displayStatusIcons] == NO)
	return;

    if (_connected == NO)
	iconName++;

    if (!iconName || iconName > ZSStatusIconMax)
      return;

    if (exclusive == YES)
      [self removeAllIcons];

    snprintf(name_buff, 128, "%s.show", _statusIconNames[iconName]);
    NSLog(@"post notify(%s)", name_buff);
    notify_post(name_buff);
}

-(void)removeIcon:(int)iconName
{
    char name_buff[128];

    if ([self displayStatusIcons] == NO)
	return;

    if (_connected == NO)
      iconName++;

    if (!iconName || iconName > ZSStatusIconMax)
      return;

    snprintf(name_buff, 128, "%s.hide", _statusIconNames[iconName]);
    NSLog(@"post notify(%s)", name_buff);
    notify_post(name_buff);
}

-(void)removeAllIcons
{
    int i = 0;
    char name_buff[128];

    for (i = -1; i < ZSStatusIconMax; i++)
      {
	snprintf(name_buff, 128, "%s.hide", _statusIconNames[i]);
	notify_post(name_buff);
	usleep(1000);
      }
}
@end

