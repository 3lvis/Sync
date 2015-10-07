@import Foundation;
@import CoreData;

#import "DATAStack.h"

@interface NSArray (Sync)

- (NSArray *)preprocessForEntity:(NSEntityDescription *)entity
                  usingPredicate:(NSPredicate *)predicate
                          parent:(NSManagedObject *)parent
                       dataStack:(DATAStack *)dataStack;

@end
