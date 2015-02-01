#import "AppDelegate.h"
#import "ANDYDataStack.h"
#import "ViewController.h"

AppDelegate *appDelegate;

@interface AppDelegate ()

@property (nonatomic, strong, readwrite) ANDYDataStack *dataStack;

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

- (ANDYDataStack *)dataStack
{
    if (_dataStack) return _dataStack;

    _dataStack = [[ANDYDataStack alloc] initWithModelName:@"Example"];

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
