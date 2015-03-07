DATASource
=================================

How much does it take to insert a NSManagedObject into Core Data and show it in your UITableView in an animated way (using NSFetchedResultsController, of course)?

100 LOC? 200 LOC? 300 LOC?

Well, DATASource does it in 10 LOC.

``` objc
DATASource *dataSource = [[DATASource alloc] initWithTableView:self.tableView 
                                                  fetchRequest:fetchRequest
                                                cellIdentifier:ANDYCellIdentifier
                                                     dataStack:self.dataStack];

dataSource.configureCellBlock = ^(UITableViewCell *cell, Task *task, NSIndexPath *indexPath) {
    cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@ (%@)", task.title, task.date, indexPath];
};

self.tableView.dataSource = self.dataSource;
```

## Installation

**DATASource** is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

`pod 'DATASource'`

## Author

Elvis Nuñez, hello@nselvis.com

## License

**DATASource** is available under the MIT license. See the LICENSE file for more info.
