#import "AppDelegate.h"
#import "DATAStack.h"
#import "ViewController.h"

AppDelegate *appDelegate;

@interface AppDelegate ()

@property (nonatomic, strong, readwrite) DATAStack *dataStack;

@end

@implementation AppDelegate

- (instancetype)init
{
    self = [super init];
    if (!self) return nil;

    appDelegate = self;

    return self;
}

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

    ViewController *mainController = [[ViewController alloc] init];
    self.window.rootViewController = mainController;

    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [self.dataStack persistContext];
}

@end
