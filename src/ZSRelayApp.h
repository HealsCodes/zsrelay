/* vim: ai ts=8 sts=4 sw=4 fdm=marker noet :
*/
#ifndef ZSRELAY_APP_H
#define ZSRELAY_APP_H

void iphone_app_main(void);

#if defined(__OBJC__)
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>

#import <UIKit/UIKit.h>

@interface ZSRelayApp : UIApplication
-(void) applicationDidFinishLaunching:(id)unused;
@end

#endif
#endif

