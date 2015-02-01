#import "ViewController.h"

#import "User.h"
#import "Data.h"

#import "ANDYFetchedResultsTableDataSource.h"
#import "ANDYDataStack.h"
#import "Kipu.h"
#import "AppDelegate.h"

@interface ViewController ()

@property (nonatomic, strong) ANDYFetchedResultsTableDataSource *dataSource;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@end

@implementation ViewController

#pragma mark - Getters

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController) return _fetchedResultsController;

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Data"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"createdDate" ascending:YES]];

    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                    managedObjectContext:[appDelegate.dataStack mainThreadContext]
                                                                      sectionNameKeyPath:nil
                                                                               cacheName:nil];

    return _fetchedResultsController;
}

- (ANDYFetchedResultsTableDataSource *)dataSource
{
    if (_dataSource) return _dataSource;

    _dataSource = [[ANDYFetchedResultsTableDataSource alloc] initWithTableView:self.tableView
                                                      fetchedResultsController:self.fetchedResultsController
                                                                cellIdentifier:@"Cell"];

    _dataSource.configureCellBlock = ^(UITableViewCell *cell, Data *item, NSIndexPath *indexPath) {
        cell.textLabel.text = item.text;
    };

    return _dataSource;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    self.tableView.dataSource = self.dataSource;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self fetchData];
}

#pragma mark -

- (void)fetchData
{
    NSURL *url = [NSURL URLWithString:@"https://api.app.net/posts/stream/global"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSOperationQueue *queue = [NSOperationQueue new];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:queue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {

                               if (connectionError) NSLog(@"connectionError: %@", connectionError);

                               if (data) {
                                   NSError *JSONSerializationError = nil;
                                   NSJSONSerialization *JSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&JSONSerializationError];
                                   if (JSONSerializationError) NSLog(@"JSONSerializationError: %@", JSONSerializationError);

                                   [Kipu processChanges:[JSON valueForKey:@"data"]
                                        usingEntityName:@"Data"
                                              dataStack:appDelegate.dataStack
                                             completion:nil];
                               }
                           }];
}

@end
