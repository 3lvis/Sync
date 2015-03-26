#import "CommentsTableViewCell.h"

@interface CommentsTableViewCell()

@property (nonatomic) UILabel *labelWithComment;
@property (nonatomic) UIView *subcommentView;

@end

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
    _labelWithComment = [UIFont font]

    return _labelWithComment;
}

#pragma mark - Implementations

- (void)updateWithComment:(NSString *)string
{

}

@end
