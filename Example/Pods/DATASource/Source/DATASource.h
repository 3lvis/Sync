@import Foundation;
@import UIKit;
@import CoreData;
@class DATAStack;

@protocol DATASourceDelegate;

typedef void (^ANDYConfigureBlock)(id cell, id item, NSIndexPath *indexPath);

@interface DATASource : NSObject <UITableViewDataSource>

@property (nonatomic, weak) id <DATASourceDelegate> delegate;

@property (nonatomic) BOOL controllerIsHidden;

@property (readonly) NSFetchedResultsController *fetchedResultsController;

/*!
 * Used to configure UITableView's cell.
 */
@property (nonatomic, copy) ANDYConfigureBlock configureCellBlock;

/*!
 * Initialization of DATASource.
 * \param tableView The used UITableView.
 * \param fetchRequest The used NSFetchedResultsController.
 * \param cellIdentifier The used cell identifier.
  * \param mainContext A NSManagedObjectContext in the main thread.
 * \returns An instance of DATASource.
 */
- (instancetype)initWithTableView:(UITableView *)tableView
                     fetchRequest:(NSFetchRequest *)fetchRequest
                   cellIdentifier:(NSString *)cellIdentifier
                      mainContext:(NSManagedObjectContext *)mainContext;

/*!
 * Convenience method to change the predicate of the NSFetchedResultsController.
 * \param predicate The predicate.
 */
- (void)changePredicate:(NSPredicate *)predicate;

@end

@protocol DATASourceDelegate <NSObject>

@optional

- (void)dataSource:(DATASource *)dataSource
   didInsertObject:(NSManagedObject *)object
     withIndexPath:(NSIndexPath *)indexPath;

- (void)dataSource:(DATASource *)dataSource
   didUpdateObject:(NSManagedObject *)object
     withIndexPath:(NSIndexPath *)indexPath;

- (void)dataSource:(DATASource *)dataSource
   didDeleteObject:(NSManagedObject *)object
     withIndexPath:(NSIndexPath *)indexPath;

- (void)dataSource:(DATASource *)dataSource
     didMoveObject:(NSManagedObject *)object
     withIndexPath:(NSIndexPath *)indexPath newIndexPath:(NSIndexPath *)newIndexPath;

@end
