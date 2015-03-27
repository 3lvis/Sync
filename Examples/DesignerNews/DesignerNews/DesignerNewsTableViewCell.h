@import UIKit;

@class Stories;

static NSString * const CellIdentifier = @"Cell";

@interface DesignerNewsTableViewCell : UITableViewCell

@property (nonatomic) Stories *story;

- (void)updateWithStory:(Stories *)story;

@end
