@import Foundation;
@import CoreData;

#import "DATAStack.h"

@interface NSArray (Sync)

- (NSArray *)preprocessForEntityNamed:(NSString *)entityName
                       usingPredicate:(NSPredicate *)predicate
                               parent:(NSManagedObject *)parent
                            dataStack:(DATAStack *)dataStack;

@end
