/* vim: ai ts=8 sts=4 sw=4 fdm=marker noet :
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

