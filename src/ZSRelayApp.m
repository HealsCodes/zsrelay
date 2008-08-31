/* vim: ai ft=objc ts=8 sts=4 sw=4 fdm=marker noet :
*/
#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#import "ZSRelayApp.h"

void
iphone_app_main (void)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    ZSRelayApp *app = [[ZSRelayApp alloc] init];

    fprintf(stderr, "Initializing App..\n");
    [app applicationDidFinishLaunching:nil];

    fprintf(stderr, "Entering CFRunLoop..\n");
    while (1)
    {
	CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.25, false);
    }

    [pool release];
}

@implementation ZSRelayApp

-(void) applicationDidFinishLaunching:(id)unused
{
    NSLog(@"App did finish launching");
}
@end

