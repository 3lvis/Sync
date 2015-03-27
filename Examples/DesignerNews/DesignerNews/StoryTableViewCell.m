#import "StoryTableViewCell.h"

#import "DNStory.h"

#import "UIFont+DNStyle.h"

static const CGFloat HYPTitleLabelMargin = 10.0;
static const CGFloat HYPTitleLabelHeight = 30.0;

static const CGFloat HYPUpdatedLabelHeight = 30.0;
static const CGFloat HYPUpdatedLabelWidth = 90.0;
static const CGFloat HYPUpdatedLabelTopMargin = 10.0;

static const CGFloat HYPCommentsCountMargin = 10.0;
static const CGFloat HYPCommentsCountHeight = 20.0;

@interface StoryTableViewCell ()

@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UILabel *updatedLabel;
@property (nonatomic) UILabel *commentCountLabel;

@end

@implementation StoryTableViewCell

#pragma mark - Initializers

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (!self) return nil;

    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.updatedLabel];
    [self.contentView addSubview:self.commentCountLabel];

    return self;
}

#pragma mark - Getters

- (UILabel *)titleLabel
{
    if (_titleLabel) return _titleLabel;

    _titleLabel = [UILabel new];
    _titleLabel.font = [UIFont headerFont];

    return _titleLabel;
}

- (UILabel *)updatedLabel
{
    if (_updatedLabel) return _updatedLabel;

    _updatedLabel = [UILabel new];
    _updatedLabel.font = [UIFont asideFont];
    _updatedLabel.textAlignment = NSTextAlignmentCenter;

    return _updatedLabel;
}

- (UILabel *)commentCountLabel
{
    if (_commentCountLabel) return _commentCountLabel;

    _commentCountLabel = [UILabel new];
    _commentCountLabel.font = [UIFont subtitleFont];

    return _commentCountLabel;
}

#pragma mark - Public methods

- (void)updateWithStory:(DNStory *)story
{
    static dispatch_once_t onceToken;
    static NSDateFormatter *formatter = nil;
    dispatch_once(&onceToken, ^{
        formatter = [NSDateFormatter new];
        formatter.dateStyle = NSDateFormatterLongStyle;
        formatter.timeStyle = NSDateFormatterNoStyle;
    });

    self.story = story;
    self.titleLabel.text = story.title;
    self.commentCountLabel.text = [NSString stringWithFormat:@"%@ comments", story.commentsCount];
    self.updatedLabel.text = [formatter stringFromDate:story.createdAt];
}

#pragma mark - Layout

- (CGRect)titleLabelFrame
{
    CGRect screenFrame = [UIScreen mainScreen].bounds;
    return CGRectMake(HYPTitleLabelMargin,
                      HYPTitleLabelMargin,
                      CGRectGetWidth(screenFrame) - HYPUpdatedLabelWidth - HYPTitleLabelMargin,
                      HYPTitleLabelHeight);
}

- (CGRect)updatedLabelFrame
{
    CGRect screenFrame = [UIScreen mainScreen].bounds;
    return CGRectMake(CGRectGetWidth(screenFrame) - HYPUpdatedLabelWidth,
                      HYPUpdatedLabelTopMargin,
                      HYPUpdatedLabelWidth,
                      HYPUpdatedLabelHeight);
}

- (CGRect)commentCountLabelFrame
{
    CGRect screenFrame = [UIScreen mainScreen].bounds;
    return CGRectMake(HYPCommentsCountMargin,
                      CGRectGetMaxY(self.updatedLabel.frame),
                      CGRectGetWidth(screenFrame) - HYPCommentsCountMargin * 2.0f,
                      HYPCommentsCountHeight);
}

- (void)setNeedsLayout
{
    [super setNeedsLayout];

    self.titleLabel.frame = [self titleLabelFrame];
    self.updatedLabel.frame = [self updatedLabelFrame];
    self.commentCountLabel.frame = [self commentCountLabelFrame];
}

@end
