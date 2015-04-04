@import UIKit;

@class DNStory;
@class DATAStack;

@interface StoryViewController : UITableViewController

- (instancetype)initWithStory:(DNStory *)story
                 andDataStack:(DATAStack *)dataStack;

@end
