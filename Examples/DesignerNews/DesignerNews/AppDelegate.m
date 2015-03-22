#import "AppDelegate.h"
#import "ViewController.h"
#import "DATAStack.h"

@interface AppDelegate ()

@property (nonatomic, strong, readwrite) DATAStack *dataStack;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    return YES;
}

#pragma mark - Core Data stack

- (void)applicationWillTerminate:(UIApplication *)application
{
    [self.dataStack persistWithCompletion:nil];
}

@end
