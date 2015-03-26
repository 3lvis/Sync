@import UIKit;

@class DNStory;

static NSString * const StoryTableViewCellIdentifier = @"StoryTableViewCellIdentifier";

@interface StoryTableViewCell : UITableViewCell

- (void)updateWithStory:(DNStory *)story;

@end
