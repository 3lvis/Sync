@import UIKit;
@import CoreData;

@class DATAStack;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, strong, readonly) DATAStack *dataStack;

@end

extern AppDelegate *appDelegate;


