#import "CommentsViewController.h"
#import "DATAStack.h"
#import "DATASource.h"

@interface CommentsViewController ()

@property (nonatomic) DATAStack *dataStack;
@property (nonatomic) DATASource *dataSource;

@end

@implementation CommentsViewController

#pragma mark - Getters

- (DATASource *)dataSource
{
    if (_dataSource) return _dataSource;

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Comments"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO]];

    return _dataSource;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.dataSource = self.dataSource;
}

- (void)viewWillAppear:(BOOL)animated
{
    self.title = self.story.title;
}

@end
