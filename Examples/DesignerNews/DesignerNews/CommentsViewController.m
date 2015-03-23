#import "CommentsViewController.h"

@interface CommentsViewController ()

@end

@implementation CommentsViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.title = self.story.title;
}

@end
