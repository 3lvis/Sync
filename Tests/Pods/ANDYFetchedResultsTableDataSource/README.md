ANDYFetchedResultsTableDataSource
=================================

How much does it take to insert a NSManagedObject into CoreData and show it in your UITableView in an animated way (using NSFetchedResultsController, of course)?

100 LOC? 200 LOC? 300 LOC?

Well, ANDYFetchedResultsTableDataSource does it in 71 LOC.

``` objc
#pragma mark - Lazy Instantiation

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController) {
        return _fetchedResultsController;
    }

    NSManagedObjectContext *context = [[ANDYDataManager sharedManager] mainContext];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Task"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]];
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                    managedObjectContext:context
                                                                      sectionNameKeyPath:nil 
                                                                               cacheName:nil];
    return _fetchedResultsController;
}

- (ANDYFetchedResultsTableDataSource *)dataSource
{
    if (_dataSource) {
        return _dataSource;
    }

    _dataSource = [[ANDYFetchedResultsTableDataSource alloc] initWithTableView:self.tableView 
                                                      fetchedResultsController:self.fetchedResultsController
                                                                cellIdentifier:ANDYCellIdentifier];
                                                                
    _dataSource.configureCellBlock = ^(UITableViewCell *cell, Task *task, NSIndexPath *indexPath) {
        cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@ (%@)", task.title, task.date, indexPath];
    };

    return _dataSource;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:ANDYCellIdentifier];
    self.tableView.dataSource = self.dataSource;

    UIBarButtonItem *addTaskButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd 
                                                                                   target:self
                                                                                   action:@selector(createTask)];
    self.navigationItem.rightBarButtonItem = addTaskButton;
}

#pragma mark - Actions

- (void)createTask
{
    [ANDYDataManager performInBackgroundContext:^(NSManagedObjectContext *context) {
        Task *task = [Task insertInManagedObjectContext:context];
        task.title = @"Hello!";
        task.date = [NSDate date];
        [context save:nil];
    }];
}
```

Attribution
===========

Based on the work of the awesome guys at [objc.io](http://www.objc.io/).

Be Awesome
==========

If something looks stupid, please create a friendly and constructive issue, getting your feedback would be awesome. Have a great day.

## Author

Elvis Nuñez, hello@nselvis.com

## License

**ANDYFetchedResultsTableDataSource** is available under the MIT license. See the LICENSE file for more info.
