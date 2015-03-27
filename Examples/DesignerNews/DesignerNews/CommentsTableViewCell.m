#import "CommentsTableViewCell.h"
#import "UIFont+DNStyle.h"

static const CGFloat HYPDistanceFromSides = 15.0;

static const CGFloat HYPWidthSubcommentView = 7.5;

@implementation CommentsTableViewCell

#pragma mark - Initializers

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (!self) return nil;

    [self.contentView addSubview:self.labelWithComment];
    [self.contentView addSubview:self.subcommentView];

    return self;
}

#pragma mark - Getters

- (UIView *)subcommentView
{
    if (_subcommentView) return _subcommentView;

    _subcommentView = [UIView new];
    _subcommentView.backgroundColor = [UIColor colorWithRed:0 green:0.59 blue:0.86 alpha:1];

    return _subcommentView;
}

- (UILabel *)labelWithComment
{
    if (_labelWithComment) return _labelWithComment;

    _labelWithComment = [UILabel new];
    _labelWithComment.font = [UIFont commentFont];

    return _labelWithComment;
}

#pragma mark - Layout

#pragma mark - Implementations

- (void)updateWithComment:(NSString *)string andSubcommentView:(BOOL)subcomment
{
    if (subcomment) {
        self.labelWithComment.frame = CGRectMake(HYPDistanceFromSides*2, HYPDistanceFromSides, [UIScreen mainScreen].bounds.size.width - HYPDistanceFromSides*3, 0);
    } else {
        self.labelWithComment.frame = CGRectMake(HYPDistanceFromSides, HYPDistanceFromSides, [UIScreen mainScreen].bounds.size.width - HYPDistanceFromSides*2, 0);
    }

    self.labelWithComment.numberOfLines = 1000;
    self.labelWithComment.text = string;
    [self.labelWithComment sizeToFit];

    if (subcomment) {
        self.subcommentView.alpha = 1;
        self.subcommentView.frame = CGRectMake(0, 0, HYPWidthSubcommentView, self.labelWithComment.frame.size.height + HYPDistanceFromSides*2);
    } else {
        self.subcommentView.alpha = 0;
    }
}

@end
