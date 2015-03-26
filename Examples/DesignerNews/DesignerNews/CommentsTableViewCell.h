@import UIKit;

static NSString * const CellIdentifier = @"Cell";

@interface CommentsTableViewCell : UITableViewCell

- (void)updateWithComment:(NSString *)string;

@end
