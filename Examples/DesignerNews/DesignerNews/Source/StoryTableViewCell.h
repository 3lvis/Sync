@import UIKit;

@class DNStory;

static NSString * const StoryTableViewCellIdentifier = @"StoryTableViewCellIdentifier";
static const CGFloat StoryTableViewCellHeight = 65.0;

@interface StoryTableViewCell : UITableViewCell

- (void)updateWithStory:(DNStory *)story;

@end
