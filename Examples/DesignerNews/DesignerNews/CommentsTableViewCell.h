@import UIKit;
#import "Stories.h"

static NSString * const CellIdentifier = @"Cell";

@interface CommentsTableViewCell : UITableViewCell

- (void)updateWithComment:(Stories *)story;

@end
