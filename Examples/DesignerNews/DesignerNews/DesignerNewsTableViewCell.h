@import UIKit;

@class Stories;

static NSString * const CellIdentifier = @"Cell";

@interface DesignerNewsTableViewCell : UITableViewCell

- (void)updateWithStory:(Stories *)story;

@end
