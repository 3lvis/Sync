#import "DesignerNewsTableViewCell.h"

@implementation DesignerNewsTableViewCell

- (void)updateWithStory:(Stories *)story
{
    if (self.labelTitle) {
        [self.labelTitle removeFromSuperview];
        [self.labelComments removeFromSuperview];
        [self.labelUpdated removeFromSuperview];
    }

    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = @"dd-MMM-yyyy";

    self.labelTitle = [[UILabel alloc] initWithFrame:CGRectMake(25, 10, self.frame.size.width - 50, self.frame.size.height - self.frame.size.height/2.5)];
    self.labelTitle.numberOfLines = 10;
    self.labelTitle.adjustsFontSizeToFitWidth = YES;
    self.labelTitle.font = [UIFont fontWithName:@"Avenir-Medium" size:18];
    self.labelTitle.text = story.title;

    self.labelComments = [[UILabel alloc] initWithFrame:CGRectMake(25, 10, self.frame.size.width - 50, self.frame.size.height - 100)];
    self.labelComments.font = [UIFont fontWithName:@"Avenir-Medium" size:14];
    self.labelComments.text = [NSString stringWithFormat:@"%d comments", story.commentCount.intValue];
    [self.labelComments sizeToFit];
    self.labelComments.frame = CGRectMake(self.frame.size.width - self.labelComments.frame.size.width - 20, self.frame.size.height - self.labelComments.frame.size.height - 7.5, self.labelComments.frame.size.width, self.labelComments.frame.size.height);

    self.labelUpdated = [[UILabel alloc] initWithFrame:CGRectMake(25, 10, self.frame.size.width - 50, self.frame.size.height - 50)];
    self.labelUpdated.numberOfLines = 10;
    self.labelUpdated.adjustsFontSizeToFitWidth = YES;
    self.labelUpdated.font = [UIFont fontWithName:@"Avenir-Medium" size:14];
    self.labelUpdated.text = [dateFormatter stringFromDate:story.createdDate];
    [self.labelUpdated sizeToFit];
    self.labelUpdated.frame = CGRectMake(25, self.frame.size.height - self.labelUpdated.frame.size.height - 10, self.labelUpdated.frame.size.width, self.labelUpdated.frame.size.height);

    [self addSubview:self.labelTitle];
    [self addSubview:self.labelComments];
    [self addSubview:self.labelUpdated];
}

@end
