@import UIKit;

static NSString * const CellIdentifier = @"Cell";

@interface CommentsTableViewCell : UITableViewCell

@property (nonatomic) UILabel *labelWithComment;
@property (nonatomic) UIView *subcommentView;

- (void)updateWithComment:(NSString *)string;

@end
