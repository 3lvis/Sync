#import "ViewController.h"

#import "User.h"
#import "Data.h"

#import "DATASource.h"
#import "DATAStack.h"
#import "Kipu.h"
#import "AppDelegate.h"

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

    return self;
}

#pragma mark - Getters

- (DATASource *)dataSource
{
    if (_dataSource) return _dataSource;

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Data"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"createdDate" ascending:YES]];

    _dataSource = [[DATASource alloc] initWithTableView:self.tableView
                                           fetchRequest:request
                                         cellIdentifier:@"Cell"
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
                                              dataStack:self.dataStack
                                             completion:nil];
                               }
                           }];
}

@end
