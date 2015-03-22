#import "ViewController.h"

#import "User.h"
#import "Data.h"

#import "DATASource.h"
#import "DATAStack.h"
#import "AppDelegate.h"
#import "Networking.h"

static NSString * const CellIdentifier = @"Cell";

@interface ViewController ()

@property (nonatomic, strong) DATASource *dataSource;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) DATAStack *dataStack;

@end

@implementation ViewController

- (instancetype)initWithDataStack:(DATAStack *)dataStack
{
    self = [super init];
    if (!self) return nil;

    _dataStack = dataStack;

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];

    return self;
}

#pragma mark - Getters

- (DATASource *)dataSource
{
    if (_dataSource) return _dataSource;

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Data"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES]];

    _dataSource = [[DATASource alloc] initWithTableView:self.tableView
                                           fetchRequest:request
                                         cellIdentifier:CellIdentifier
                                            mainContext:self.dataStack.mainContext];

    _dataSource.configureCellBlock = ^(UITableViewCell *cell, Data *item, NSIndexPath *indexPath) {
        cell.textLabel.text = item.text;
    };

    return _dataSource;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.dataSource = self.dataSource;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self fetchData];
}

#pragma mark - Sync

- (void)fetchData
{
    Networking *networking = [[Networking alloc] initWithDataStack:self.dataStack];
    [networking fetchPosts];
}

@end
