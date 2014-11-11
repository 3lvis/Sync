//
//  ANDYFetchedResultsTableDataSource.m
//  Andy
//
//  Created by Elvis Nunez on 10/29/13.
//  Based on the work of Chris Eidhof.
//  Copyright (c) 2014 Elvis Nuñez. All rights reserved.
//

#import "ANDYFetchedResultsTableDataSource.h"

@interface ANDYFetchedResultsTableDataSource () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSString *cellIdentifier;

@end

@implementation ANDYFetchedResultsTableDataSource

- (instancetype)initWithTableView:(UITableView *)aTableView
         fetchedResultsController:(NSFetchedResultsController *)aFetchedResultsController
                   cellIdentifier:(NSString *)aCellIdentifier
{
    self = [super init];
    if (!self) return nil;

    self.tableView = aTableView;
    self.fetchedResultsController = aFetchedResultsController;
    self.cellIdentifier = aCellIdentifier;

    self.tableView.dataSource = self;
    self.fetchedResultsController.delegate = self;
    [self.fetchedResultsController performFetch:NULL];

    return self;
}

- (void)changePredicate:(NSPredicate *)predicate
{
    NSAssert(self.fetchedResultsController.cacheName == NULL, @"Can't change predicate when you have a caching fetched results controller");
    NSFetchRequest* fetchRequest = self.fetchedResultsController.fetchRequest;
    fetchRequest.predicate = predicate;
    [self.fetchedResultsController performFetch:NULL];
    [self.tableView reloadData];
}

- (id)itemAtIndexPath:(NSIndexPath *)path
{
    if (path.row < [[self.fetchedResultsController fetchedObjects] count]) {
        return [self.fetchedResultsController objectAtIndexPath:path];
    }
    return nil;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)path
{
    id item = [self itemAtIndexPath:path];
    if (self.configureCellBlock) {
        self.configureCellBlock(cell, item, path);
    }
}

#pragma mark UITableViewDataSource


- (NSInteger)numberOfSectionsInTableView:(UITableView*)aTableView
{
    return self.fetchedResultsController.sections.count;
}

- (NSInteger)tableView:(UITableView*)aTableView numberOfRowsInSection:(NSInteger)section
{
    NSUInteger i = [self.fetchedResultsController.sections[(NSUInteger) section] numberOfObjects];
    return i;
}

- (NSString*)tableView:(UITableView*)aTableView titleForHeaderInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> info = [self.fetchedResultsController sections][(NSUInteger) section];
    return info.name;
}

- (UITableViewCell*)tableView:(UITableView*)aTableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell = [aTableView dequeueReusableCellWithIdentifier:self.cellIdentifier forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}


#pragma mark NSFetchedResultsControllerDelegate

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

- (void)controllerWillChangeContent:(NSFetchedResultsController*)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                     withRowAnimation:UITableViewRowAnimationAutomatic];
            break;

        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                     withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        default:
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            if ([self.delegate respondsToSelector:@selector(dataSource:didInsertObject:withIndexPath:)]) {
                [self.delegate dataSource:self didInsertObject:anObject withIndexPath:indexPath];
            }
            break;

        case NSFetchedResultsChangeDelete: {
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            if ([self.delegate respondsToSelector:@selector(dataSource:didDeleteObject:withIndexPath:)]) {
                [self.delegate dataSource:self didDeleteObject:anObject withIndexPath:indexPath];
            }
        }
            break;

        case NSFetchedResultsChangeUpdate:
            if([self.tableView.indexPathsForVisibleRows indexOfObject:indexPath] != NSNotFound) {
                [self configureCell:[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
                if ([self.delegate respondsToSelector:@selector(dataSource:didUpdateObject:withIndexPath:)]) {
                    [self.delegate dataSource:self didUpdateObject:anObject withIndexPath:indexPath];
                }
            }
            break;

        case NSFetchedResultsChangeMove:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        default:
            break;
    }
}

@end
