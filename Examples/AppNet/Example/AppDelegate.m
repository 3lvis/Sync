#import "AppDelegate.h"
#import "DATAStack.h"
#import "ViewController.h"

@interface AppDelegate ()

@property (nonatomic) DATAStack *dataStack;

@end

@implementation AppDelegate

#pragma mark - Getters

- (DATAStack *)dataStack
{
    if (_dataStack) return _dataStack;

    _dataStack = [[DATAStack alloc] initWithModelName:@"Example"];

    return _dataStack;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    ViewController *mainController = [[ViewController alloc] initWithDataStack:self.dataStack];
    self.window.rootViewController = mainController;
    [self.window makeKeyAndVisible];

    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [self.dataStack persistWithCompletion:nil];
}

@end
