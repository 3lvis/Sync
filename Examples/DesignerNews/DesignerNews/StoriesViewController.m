#import "StoriesViewController.h"
#import "StoryViewController.h"
#import "StoryTableViewCell.h"
#import "DATAStack.h"
#import "APIClient.h"
#import "DATASource.h"
#import "DNStory.h"

@interface StoriesViewController () <NSFetchedResultsControllerDelegate>

@property (nonatomic, weak) DATAStack *dataStack;
@property (nonatomic) DATASource *dataSource;

@end

@implementation StoriesViewController

#pragma mark - Initializers

- (instancetype)initWithDataStack:(DATAStack *)dataStack
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (!self) return nil;

    _dataStack = dataStack;

    return self;
}

#pragma mark - Getters

- (DATASource *)dataSource
{
    if (_dataSource) return _dataSource;

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Story"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"createdAt"
                                                              ascending:NO]];

    _dataSource = [[DATASource alloc] initWithTableView:self.tableView
                                           fetchRequest:request
                                         cellIdentifier:StoryTableViewCellIdentifier
                                            mainContext:self.dataStack.mainContext];

    _dataSource.configureCellBlock = ^(StoryTableViewCell *cell,
                                       DNStory *story,
                                       NSIndexPath *indexPath) {
        [cell updateWithStory:story];
    };

    return _dataSource;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    APIClient *client = [APIClient new];
    [client fetchStoryUsingDataStack:self.dataStack];

    [self.tableView registerClass:[StoryTableViewCell class]
           forCellReuseIdentifier:StoryTableViewCellIdentifier];
    self.tableView.dataSource = self.dataSource;
    self.tableView.rowHeight = HYPRowHeight;

    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.topItem.title = @"";

    self.title = @"Designer News";
}

#pragma mark - UIViewController

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - UITableViewDataSource

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DNStory *story = [self.dataSource.fetchedResultsController objectAtIndexPath:indexPath];
    StoryViewController *viewController = [[StoryViewController alloc] initWithStory:story
                                                                        andDataStack:self.dataStack];
    [self.navigationController pushViewController:viewController
                                         animated:YES];
}


@end
