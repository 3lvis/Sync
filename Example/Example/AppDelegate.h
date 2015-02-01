@import UIKit;
@import CoreData;

@class ANDYDataStack;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, strong, readonly) ANDYDataStack *dataStack;

@end

extern AppDelegate *appDelegate;


