#import "ViewController.h"
#import "CommentsViewController.h"
#import "DesignerNewsTableViewCell.h"
#import "DATAStack.h"
#import "APIClient.h"
#import "DATASource.h"
#import "Stories.h"

@interface ViewController () <NSFetchedResultsControllerDelegate>

@property (nonatomic) DATAStack *dataStack;
@property (nonatomic) DATASource *dataSource;
@property (nonatomic) NSMutableArray *arrayWithStories;

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
    self.arrayWithStories = [NSMutableArray arrayWithArray:[self.dataStack.mainContext executeFetchRequest:request error:nil]];

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
    Stories *storySelected = self.arrayWithStories[indexPath.row];
    CommentsViewController *viewController = [CommentsViewController new];
    viewController.story = storySelected;
    [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Designer News";

    APIClient *client = [APIClient new];
    [client fetchStoriesUsingDataStack:self.dataStack];

    [self.tableView registerClass:[DesignerNewsTableViewCell class] forCellReuseIdentifier:CellIdentifier];
    self.tableView.dataSource = self.dataSource;
    self.tableView.rowHeight = 65.0f;
}

#pragma mark - UIViewController

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end
