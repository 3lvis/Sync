@import UIKit;

static NSString * const CommentTableViewCellIdentifier = @"CommentTableViewCellIdentifier";

@interface CommentTableViewCell : UITableViewCell

@property (nonatomic) UILabel *labelWithComment;
@property (nonatomic) UIView *subcommentView;

- (void)updateWithComment:(NSString *)string andSubcommentView:(BOOL)subcomment;

@end
