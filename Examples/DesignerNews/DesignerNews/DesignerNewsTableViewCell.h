@import UIKit;
#import "Stories.h"

@interface DesignerNewsTableViewCell : UITableViewCell

@property (nonatomic) UILabel *labelTitle;
@property (nonatomic) UILabel *labelUpdated;
@property (nonatomic) UILabel *labelComments;

- (void)updateWithStory:(Stories *)story;

@end
