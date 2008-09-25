/* vim: ai ts=8 sts=4 sw=4 fdm=marker noet :
*/

#import "ZSLauncher.h"
#include <dlfcn.h>

/* prototypes for WiFi scan and association */
#define WIFI_IFACE @"en0"

#if IPHONE_OS_RELEASE == 1
#define PREF_FRAMEWORK "/System/Library/Frameworks/Preferences.framework/Prefernces"
#else
#define PREF_FRAMEWORK "/System/Library/PrivateFrameworks/Preferences.framework/Preferences"
#endif

 #define kAppNetwork	    CFSTR("com.apple.preferences.network")
 #define kKeyWifiNetwork    CFSTR("wifi-network")

static void *dyld_handle = NULL;

static int (*__Apple80211Open)(Apple80211Ref *ctx) = NULL;
static int (*__Apple80211Close)(Apple80211Ref ctx) = NULL;

static int (*__Apple80211BindToInterface)(Apple80211Ref handle, CFStringRef interface) = NULL;
static int (*__Apple80211Scan)(Apple80211Ref handle, CFArrayRef *list, CFDictionaryRef parameters) = NULL;
static int (*__Apple80211Associate)(Apple80211Ref handle, CFDictionaryRef bss, CFStringRef password) = NULL;

static int (*___SetWiFiEnabled)(BOOL val) = NULL;

#define BIND_SYMBOL(sym, handle)    \
    {									    \
	__##sym = dlsym(handle, #sym);				    \
	if (__##sym == NULL)						    \
	{								    \
	    fprintf(stderr, "Bind %s - %s\n", "__"#sym, dlerror());	    \
	    return 1;							    \
	}								    \
    }

int
_InitApple80211 (void)
{
    fprintf(stderr, "dlopen()..\n");
    dyld_handle = dlopen(PREF_FRAMEWORK, RTLD_LAZY);
    if (dyld_handle == NULL)
    {
	fprintf(stderr, "dlopen(): %s", dlerror());
	return 1;
    }

    BIND_SYMBOL(Apple80211Open , dyld_handle);
    BIND_SYMBOL(Apple80211Close, dyld_handle);
    BIND_SYMBOL(Apple80211BindToInterface, dyld_handle);
    BIND_SYMBOL(Apple80211Scan           , dyld_handle);
    BIND_SYMBOL(Apple80211Associate, dyld_handle);
    BIND_SYMBOL(_SetWiFiEnabled, dyld_handle);

    fprintf(stderr, "bound to library.\n");
    return 0;
}

void
_DestroyApple8011 (void)
{
    dlclose(dyld_handle);
}

@implementation ZSLauncher (Apple80211)
-(BOOL)bringUpWiFi
{
    if (_InitApple80211() != 0)
    {
	return NO;
    }

    ___SetWiFiEnabled(NO);
    CFPreferencesSetAppValue(kKeyWifiNetwork, kCFBooleanFalse, kAppNetwork);
    CFPreferencesAppSynchronize(kAppNetwork);
    sleep(2);
    CFPreferencesSetAppValue(kKeyWifiNetwork, kCFBooleanTrue, kAppNetwork);
    CFPreferencesAppSynchronize(kAppNetwork);
    ___SetWiFiEnabled(YES);

    if (_handle == NULL)
    {
	__Apple80211Open(&_handle);
	if (_handle == NULL)
	{
	    NSLog(@"_Apple80211Open: failed");
	    return NO;
	}
    }

    /* get our settings */
    _netInfo = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"org.bitspin.zsrelay.launcher"];
    if (_netInfo == nil)
    {
	/* factory defaults */
	[[NSUserDefaults standardUserDefaults] setObject:@"Apollon"
						  forKey:@"ESSID"];

	[[NSUserDefaults standardUserDefaults] setObject:@""
						  forKey:@"BSSID"];

	[[NSUserDefaults standardUserDefaults] setInteger:1
						   forKey:@"security"];

	[[NSUserDefaults standardUserDefaults] setObject:@"ole1234567890"
						forKey:@"key"];

	[[NSUserDefaults standardUserDefaults] setBool:NO
						forKey:@"killWifi"];

	[[NSUserDefaults standardUserDefaults] setBool:NO
						forKey:@"debug"];

	[[NSUserDefaults standardUserDefaults] synchronize];
	_netInfo = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"org.bitspin.zsrelay.launcher"];
    }
    _netInfo = [[NSDictionary alloc] initWithDictionary:_netInfo];
    __Apple80211BindToInterface(_handle, WIFI_IFACE);
    return YES;
}

-(BOOL)isNetworkAvailable
{
    int i = 0;
    NSArray *found       = nil;
    NSDictionary *params = [[NSDictionary alloc] init];

    __Apple80211Scan(_handle, &found, params);

    for (i = 0; i < [found count]; i++)
    {
	NSDictionary *network = [found objectAtIndex:i];

	NSString *essid = [network objectForKey:@"SSID_STR"];
	NSString *bssid = [network objectForKey:@"BSSID"];
	int wep         = [[network objectForKey:@"WEP"] intValue];
	int wpa         = [[network objectForKey:@"WPA"] intValue];

//	NSString *msg = [[NSString alloc] initWithFormat:@"Found %@ (WEP:%d)", essid, wep, nil];
//	[self showStatus:msg];
//	[msg release];

	NSLog(@"Scan: [%@] '%@' (WEP:%d,WPA:%d)", bssid, essid, wep, wpa);
	if ([[_netInfo objectForKey:@"ESSID"] length] >= 1)
	{
	    if ([essid compare:[_netInfo objectForKey:@"ESSID"]] != NSOrderedSame)
	    {
		NSLog(@"- ESSID doesn't match (expected '%@').",
		      [_netInfo objectForKey:@"ESSID"]);
		continue;
	    }
	}
	if ([[_netInfo objectForKey:@"BSSID"] length] >= 1)
	{
	    if ([bssid compare:[_netInfo objectForKey:@"BSSID"]] != NSOrderedSame)
	    {
		NSLog(@"- BSSID doesn't match (expected '%@').",
		      [_netinfo objectForKey:@"BSSID"]);
		continue;
	    }
	}
	if ([[_netInfo objectForKey:@"security"] intValue] == 0 && (wep != 0 || wpa != 0))
	{
	    NSLog(@"- Expected open network");
	    continue;
	}
	else
	{
	    if (([[_netInfo objectForKey:@"security"] intValue] == 1  && wep == 0) ||
		([[_netInfo objectForKey:@"security"] intValue] != 1  && wep == 1))
	    {
		NSLog(@"- WEP mismatch");
		continue;
	    }

	    if (([[_netInfo objectForKey:@"security"] intValue] == 2 && wpa == 0) ||
		([[_netInfo objectForKey:@"security"] intValue] != 2 && wpa == 1))
	    {
		NSLog(@"- WPA mismatch");
		continue;
	    }
	}

        _bssData = [[NSDictionary alloc] initWithDictionary:network];
        NSLog(@"- Required parameters match.");
	break;
    }

    [found release];
    [params release];

    if (_bssData != nil)
    {
	return YES;
    }

    return NO;
}

-(BOOL)bindToNetwork
{
    if (_bssData == nil)
    {
	return NO;
    }

    if ([[_netInfo objectForKey:@"key"] length] >= 1 &&
	[[_netInfo objectForKey:@"security"] intValue] != 0)
    {
	__Apple80211Associate(_handle, _bssData, [_netInfo objectForKey:@"key"]);
    }
    else
    {
	__Apple80211Associate(_handle, _bssData, nil);
    }

    return YES;
}

-(BOOL)finalizeWiFi
{
    if ([[_netInfo objectForKey:@"killWifi"] boolValue] == YES)
    {
	___SetWiFiEnabled(NO);
	CFPreferencesSetAppValue(kKeyWifiNetwork, kCFBooleanFalse, kAppNetwork);
	CFPreferencesAppSynchronize(kAppNetwork);
    }
    if (_handle)
    {
	__Apple80211Close(_handle);
	_DestroyApple8011();
    }
}

@end


