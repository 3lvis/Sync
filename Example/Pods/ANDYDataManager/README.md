ANDYDataManager
===================

This is class that helps you to aliviate the Core Data boilerplate. Now you can go to your AppDelegate remove all the Core Data related code and replace it with:

``` objc
- (void)applicationWillTerminate:(UIApplication *)application
{
    [[ANDYDataManager sharedManager] persistContext];
}
```

Then in your NSFetchedResultsController backed app (attached to your main context). You can do this:

``` objc
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

**BOOM, it just works.**

(Hint: Maybe you haven't found the best way to use NSFetchedResultsController, well [here it is](https://github.com/NSElvis/ANDYFetchedResultsTableDataSource).)

Be Awesome
==========

If something looks stupid, please create a friendly and constructive issue, getting your feedback would be awesome. Have a great day.
