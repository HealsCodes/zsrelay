/* vim: ai ft=objc ts=8 sts=4 sw=4 fdm=marker noet :
*/
#import "ZSLauncher.h"

int
main (int argc, char **argv)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
#if IPHONE_OS_RELEASE == 1
    int ret = UIApplicationMain(argc, argv, [ZSLauncher class]);
#else
    int ret = UIApplicationMain(argc, argv, @"ZSLauncher", @"ZSLauncher");
#endif
    [pool release];

    return ret;
}

