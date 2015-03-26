@import UIKit;
@class DATAStack;
@class DATASource;
#import "Stories.h"

@interface CommentsViewController : UITableViewController

@property (nonatomic) Stories *story;
@property (nonatomic) DATAStack *dataStack;

@end
