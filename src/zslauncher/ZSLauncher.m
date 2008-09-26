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

#import "ZSLauncher.h"

@implementation ZSLauncher

-(void)applicationDidFinishLaunching:(NSNotification*)aNotification
{
    _handle   = NULL;
    _bssData  = nil;
    _progress = nil;
    _netInfo  = nil;

    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"debug"] == YES)
    {
	freopen("/tmp/zslauncher.log", "a", stderr);
	NSLog(@"debug enabled");
    }

    [self setStatusBarShowsProgress:YES];
    [self setStatusBarMode:2
		  duration:0.0f];

    _window = [[[UIWindow alloc] initWithContentRect:
		[UIHardware fullScreenApplicationContentRect]] autorelease];

    CGRect windowRect = [UIHardware fullScreenApplicationContentRect];
    windowRect.origin.x = windowRect.origin.y = 0.0f;

    _mainView = [[UIView alloc] initWithFrame:windowRect];

    [_mainView becomeFirstResponder];
    [_window setContentView:_mainView];
    [_window orderFront:self];

#if IPHONE_OS_RELEASE == 1
    [_window makeKey:self];
    [_window _setHidden:No];
#else
    [_window makeKeyAndVisible];
#endif

    UIImageView *background = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Default.png"]];
    [_mainView addSubview:background];

    _progress = [[UIProgressHUD alloc] initWithWindow:_window];
    [_progress drawRect:windowRect];
    [_progress show:YES];


    [_mainView addSubview:_progress];

    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"suspended"] == YES)
    {
	[self showStatus:@"Terminating..."];
	[self terminateWithSuccess];
    }

    [self showStatus:@"Loading..."];
    [NSTimer scheduledTimerWithTimeInterval:0.1
				     target:self
				   selector:@selector(enableProxy:)
				   userInfo:nil
				    repeats:NO];
}

-(void)applicationDidResume
{

    NSLog(@"Application did Resume");

    [self removeApplicationBadge];
    [self terminate];
}


-(void)applicationWillTerminate
{
    FILE *fd = NULL;
    fd = popen("/usr/sbin/zscmd stop", "r");

    NSLog(@"Application will Terminate");
    if (fd != NULL)
    {
	sleep(2);
	fclose(fd);
    }
    [self removeApplicationBadge];
    [[NSUserDefaults standardUserDefaults] setBool:NO
					    forKey:@"suspended"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [selfe finalizeWiFi];
}

-(void)showStatus:(NSString*)aString
{
    NSLog(@"Preparing to update status...");
//    [_progress show:NO];

    NSString *localizedString = [[NSBundle mainBundle] localizedStringForKey:aString
								       value:@""
								       table:nil];

    if (localizedString != nil)
    {
	NSLog(@"Now displaying localized: %@", aString);
	[_progress setText:aString];
    }
    else
    {
	NSLog(@"Now displaying: %@", aString);
	[_progress setText:aString];
    }

    [_progress show:YES];

    [_mainView setNeedsDisplay];
    [_progress setNeedsDisplay];
}

-(void)enableProxy:(NSTimer*)aTimer
{
    static int step=0;

    switch(step)
    {
	case 0:
        [self showStatus:@"Enabling WiFi.."];

	if ([self bringUpWiFi] == NO)
	{
	    [self showStatus:@"Unable to enable WiFi!"];
	    step = 6;
	}
	break;

    case 1:
	[self showStatus:@"Scanning for Network.."];
	if ([self isNetworkAvailable] == NO)
	{
	    sleep(4);
	    step--;
	}
	break;

    case 2:
	[self showStatus:@"Enabling proxy..."];
	{
	    FILE *fd = NULL;
	    fd = popen("/usr/sbin/zscmd start", "r");

	    if (fd == NULL)
	    {
		[self showStatus:@"Failed to start proxy!"];
		step = 6;
		break;
	    }
	    fclose(fd);
	}
	break;

    case 3:
        [self showStatus:@"Connecting..."];
	if ([self bindToNetwork] == NO)
	{
	    [self showStatus:@"Failed to connect!"];
	    step = 6;
	}
	break;

    case 4:
	[self showStatus:@"Have fun!"];
	[_progress done];
	sleep(1);
	break;

    case 5:
        [[NSUserDefaults standardUserDefaults] setBool:YES
						forKey:@"suspended"];
        [[NSUserDefaults standardUserDefaults] synchronize];

	[_progress show:NO];
	[self setApplicationBadge:@"On"];
	[self suspendWithAnimation:YES];
	return;
	break;

    case 6:
    case 7:
	sleep(3);
	[_progress show:NO];
	[self terminate];
	break;
    }
    step++;

    [NSTimer scheduledTimerWithTimeInterval:0.1
				     target:self
				   selector:@selector(enableProxy:)
				   userInfo:nil
				    repeats:NO];
}
@end

/* vim: ai ft=objc ts=8 sts=4 sw=4 fdm=marker noet :
*/

