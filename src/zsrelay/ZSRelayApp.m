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

#ifdef HAVE_NLIST_H
#include <mach-o/nlist.h>
#endif

#import "ZSRelayApp.h"

#include <unistd.h>
#include <signal.h>
#include <fcntl.h>
#include <sys/sysctl.h>
#include <sys/types.h>
#include <stdlib.h>

//From Nate True's dock application:
static pid_t
springboard_pid() {
    uint32_t		    i;
    size_t		    length;
    int32_t		    err, count;
    struct kinfo_proc	   *process_buffer;
    struct kinfo_proc      *kp;
    int			    mib[ 3 ] = { CTL_KERN, KERN_PROC, KERN_PROC_ALL };
    pid_t		    spring_pid;
    int			    loop;

    spring_pid = -1;

    sysctl( mib, 3, NULL, &length, NULL, 0 );

    if (length == 0)
	return -1;

    process_buffer = (struct kinfo_proc *)malloc(length);

    for ( i = 0; i < 60; ++i ) {
	// in the event of inordinate system load, transient sysctl() failures are
	// possible.  retry for up to one minute if necessary.
	if ( ! ( err = sysctl( mib, 3, process_buffer, &length, NULL, 0 ) ) ) break;
	sleep( 1 );
    }	

    if (err) {
	free(process_buffer);
	return -1;
    }

    count = length / sizeof(struct kinfo_proc);

    kp = process_buffer;

    for (loop = 0; (loop < count) && (spring_pid == -1); loop++) {
	if (!strcasecmp(kp->kp_proc.p_comm,"SpringBoard")) {
	    spring_pid = kp->kp_proc.p_pid;
	}
	kp++;
    }

    free(process_buffer);

    return spring_pid;
}

static uid_t
springboard_uid()
{
    uint32_t		i;
    size_t		length;
    int32_t		err, count;
    struct kinfo_proc	*process_buffer;
    struct kinfo_proc   *kp;
    int			mib[ 3 ] = { CTL_KERN, KERN_PROC, KERN_PROC_ALL };
    uid_t		spring_uid;
    int			loop;

    spring_uid = -1;

    sysctl( mib, 3, NULL, &length, NULL, 0 );

    if (length == 0)
	return -1;

    process_buffer = (struct kinfo_proc *)malloc(length);

    for ( i = 0; i < 60; ++i ) {
	// in the event of inordinate system load, transient sysctl() failures are
	// possible.  retry for up to one minute if necessary.
	if ( ! ( err = sysctl( mib, 3, process_buffer, &length, NULL, 0 ) ) ) break;
	sleep( 1 );
    }	

    if (err) {
	free(process_buffer);
	return -1;
    }

    count = length / sizeof(struct kinfo_proc);

    kp = process_buffer;

    for (loop = 0; (loop < count) && (spring_uid == -1); loop++) {
	if (!strcasecmp(kp->kp_proc.p_comm,"SpringBoard")) {
	    spring_uid = kp->kp_eproc.e_pcred.p_ruid;
	}
	kp++;
    }

    free(process_buffer);

    return spring_uid;
}


void
iphone_app_main (void)
{
    while(springboard_pid() == -1)
    {
	sleep(4);
    }

    printf("Springboard uid: %i\n", springboard_uid());

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    ZSRelayApp *app = [[ZSRelayApp alloc] init];

    [app applicationDidFinishLaunching:nil];

    while (1)
    {
	CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.25, false);
    }

    [pool release];
}

void
iphone_app_handle_signals (int unused)
{
    printf("iphone_app_handle_signal()\n");
    if ([ZSRelayApp sharedApp:nil] != nil)
    {
	[[ZSRelayApp sharedApp:nil] applicationWillTerminate];
    }

    cleanup();
    exit(0);
}

void
iphone_app_handle_notify (CFNotificationCenterRef center, void *observer,
			  CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    printf("iphone_app_handle_notify()\n");
    [(ZSRelayApp*)observer applicationWillTerminate];
}

@implementation ZSRelayApp
+(ZSRelayApp*)sharedApp:(ZSRelayApp*)newInstance
{
    static ZSRelayApp *_sharedApp = nil;

    if (newInstance != nil && _sharedApp == nil)
    {
	_sharedApp = newInstance;
    }

    return _sharedApp;
}

-(void)applicationDidFinishLaunching:(id)unused
{
    _connected = NO;
    _urlConnection = nil;

    [ZSRelayApp sharedApp:self];
    /* register signal handling */
/*
    signal(SIGTERM, iphone_app_handle_signals);
    signal(SIGKILL, iphone_app_handle_signals);
    signal(SIGSEGV, iphone_app_handle_signals);
*/
    /* register for darwin notifications */
    [self registerNotifications];



    setuid(springboard_uid());
    sleep(2);

    [self applicationNeedsReConfigure];
}

-(void)applicationNeedsReConfigure
{
    _connected = NO;

    [self removeAllIcons];
    [self setNetworkKeepAlive:NO];

    if ([self loadSettings] == NO)
    {
	NSLog(@"failed to load settings!");
	return;
    }
    NSLog(@"got settings.");

    NSLog(@"use status icons: %d", [self displayStatusIcons]);
    [self showIcon:@"ZSRelay"];

    NSLog(@"use network keep alive: %d", [self networkKeepAlive]);
    if ([self networkKeepAlive] == YES)
    {
	NSLog(@"registring io hook...");
	if ([self setNetworkKeepAlive:YES] == YES)
	{
	    NSLog(@"hook registred");
	    [self showIcon:@"ZSRelayInsomnia"];
	}
	else
	{
	    NSLog(@"failed to register hook");
	}
    }
    if ([self sshOnLaunch] == YES)
    {
	FILE *fd = NULL;
	fd = popen("/usr/sbin/zscmd ssh-on", "r");

	if (fd != NULL)
	{
	    fclose(fd);
	}
    }

    /* send at least one keep alive */
    [self connectionKeepAlive];
}

-(void)applicationWillTerminate
{
    /* remove all possible icons and disable notifications */
    [self removeAllIcons];
    [self removeNotifications];
    [self setNetworkKeepAlive:NO];
    [self unloadSettings];

    if ([self sshOnLaunch] == YES)
    {
	FILE *fd = NULL;
	fd = popen("/usr/sbin/zscmd ssh-off", "r");

	if (fd != NULL)
	{
	    fclose(fd);
	}
    }
}
@end

/* vim: ai ft=objc ts=8 sts=4 sw=4 fdm=marker noet :
*/

