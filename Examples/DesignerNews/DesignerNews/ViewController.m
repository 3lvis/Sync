#import "ViewController.h"
#import "CommentsViewController.h"
#import "DesignerNewsTableViewCell.h"
#import "DATAStack.h"
#import "APIClient.h"
#import "DATASource.h"
#import "Stories.h"

static const CGFloat HYPRowHeight = 65.0f;

@interface ViewController () <NSFetchedResultsControllerDelegate>

@property (nonatomic) DATAStack *dataStack;
@property (nonatomic) DATASource *dataSource;

@end

@implementation ViewController

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

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Stories"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO]];

    _dataSource = [[DATASource alloc] initWithTableView:self.tableView
                                           fetchRequest:request
                                         cellIdentifier:CellIdentifier
                                            mainContext:self.dataStack.mainContext];

    _dataSource.configureCellBlock = ^(DesignerNewsTableViewCell *cell, Stories *story, NSIndexPath *indexPath) {
        [cell updateWithStory:story];
    };

    return _dataSource;
}

#pragma mark - TableView methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DesignerNewsTableViewCell *cell = (DesignerNewsTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    Stories *storySelected = cell.story;
    CommentsViewController *viewController = [CommentsViewController new];
    [self.navigationController pushViewController:viewController animated:YES];
    viewController.story = storySelected;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    APIClient *client = [APIClient new];
    [client fetchStoriesUsingDataStack:self.dataStack];

    [self.tableView registerClass:[DesignerNewsTableViewCell class] forCellReuseIdentifier:CellIdentifier];
    self.tableView.dataSource = self.dataSource;
    self.tableView.rowHeight = HYPRowHeight;

    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.topItem.title = @"";

    self.title = @"Designer News";
}

@end
