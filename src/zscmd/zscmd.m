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

#include <stdio.h>
#include <libgen.h>
#include <CoreFoundation/CoreFoundation.h>
#include <Foundation/Foundation.h>

#include "zsipc.h"

#if 0
static void insertPrefBundle(NSString* settingsFile);
static void removePrefBundle(NSString* settingsFile);
#endif

int
main (int argc, char **argv)
{
    int ret = 1;
    ZSIPCRef zsIPC = ZSInitMessaging();
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    if (argc == 1)
      {
	printf("argv[0] = '%s'\n", argv[0]);

	if (strcmp("org.bitspin.zsrelay.start", basename(argv[0])) == 0)
	  {
	    ret = system("/bin/launchctl load -w /Library/LaunchDaemons/org.bitspin.zsrelay.plist");
	  }
	else if (strcmp("org.bitspin.zsrelay.stop", basename(argv[0])) == 0)
	  {
	    ZSSendCommand(zsIPC, ZSMsgDoTerminate);
	    ret = system("/bin/launchctl unload -w /Library/LaunchDaemons/org.bitspin.zsrelay.plist");
	  }
      }
    else if (argc >= 2)
      {
	if (strncmp("start", argv[1], 4) == 0)
	  {
	    ret = system("/bin/launchctl load -w /Library/LaunchDaemons/org.bitspin.zsrelay.plist");
	  }
	else if (strncmp("stop", argv[1], 4) == 0)
	  {
	    ZSSendCommand(zsIPC, ZSMsgDoTerminate);
	    ret = system("/bin/launchctl unload -w /Library/LaunchDaemons/org.bitspin.zsrelay.plist");
	  }
	else if (strncmp("reconf", argv[1], 6) == 0)
	  {
	    ZSSendCommand(zsIPC, ZSMsgDoReConfig);
	  }
	else if (strncmp("status", argv[1], 6) == 0)
	  {
	    long trafficIn   = 0,
		 trafficOut  = 0,
		 connections = 0;

	    ZSPollTrafficStats(zsIPC, &trafficIn, &trafficOut, &connections);
	    printf("traffic stats\n"
		   "---------------\n"
		   "connections: %d\n"
		   "traffic in : %ld byte\n"
		   "traffic out: %ld byte\n",
		   connections,
		   trafficIn,
		   trafficOut);
	  }
	else if(strncmp("install-plugin", argv[1], 14) == 0)
	  {
	    ;
	  }
	else if(strncmp("remove-plugin", argv[1], 13) == 0)
	  {
	    ;
	  }
	if (strncmp("ssh-on", argv[1], 7) == 0)
	  {
	    ;
	  }
	else if (strncmp("ssh-off", argv[1], 7) == 0)
	  {
	    ;
	  }
	ret = 0;
      }
    if (ret != 0)
      {
	fprintf(stderr, "usage: %s command\n"
		"supported commands include:\n"
		"  start/stop     - start / stop zsrelay\n"
		"  status         - poll and display traffic stats\n"
		"  reconf         - trigger config reload\n"
		"\n",
		argv[0]);
      }
    ZSDestroy(zsIPC);
    [pool release];
    return ret;
}

