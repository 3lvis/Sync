@import XCTest;
@import CoreData;

@import DATAStack;
#import "Sync.h"

@interface BaseTestCase : XCTestCase

- (id)objectsFromJSON:(NSString *)fileName;

- (DATAStack *)dataStackWithModelName:(NSString *)modelName;

- (NSInteger)countForEntity:(NSString *)entity
                  inContext:(NSManagedObjectContext *)context;

- (NSInteger)countForEntity:(NSString *)entity
                  predicate:(NSPredicate *)predicate
                  inContext:(NSManagedObjectContext *)context;

- (NSArray *)fetchEntity:(NSString *)entity
               inContext:(NSManagedObjectContext *)context;

- (NSArray *)fetchEntity:(NSString *)entity
               predicate:(NSPredicate *)predicate
               inContext:(NSManagedObjectContext *)context;

- (NSArray *)fetchEntity:(NSString *)entity
         sortDescriptors:(NSArray *)sortDescriptors
               inContext:(NSManagedObjectContext *)context;

- (NSArray *)fetchEntity:(NSString *)entity
               predicate:(NSPredicate *)predicate
         sortDescriptors:(NSArray *)sortDescriptors
               inContext:(NSManagedObjectContext *)context;
@end
