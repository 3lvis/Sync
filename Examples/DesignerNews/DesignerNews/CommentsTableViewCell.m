#import "CommentsTableViewCell.h"
#import "UIFont+DNStyle.h"

static const CGFloat HYPDistanceFromSides = 15.0;

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

- (void)updateWithComment:(NSString *)string
{
    self.labelWithComment.frame = CGRectMake(HYPDistanceFromSides, HYPDistanceFromSides, [UIScreen mainScreen].bounds.size.width - HYPDistanceFromSides*2, 0);
    self.labelWithComment.text = string;
    self.labelWithComment.numberOfLines = 1000;
    [self.labelWithComment sizeToFit];
}

@end
