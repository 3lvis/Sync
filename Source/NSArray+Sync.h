@import Foundation;
@import CoreData;

#import "DATAStack.h"

@interface NSArray (Sync)

- (void)preprocessForEntity:(NSEntityDescription *)entity
             usingPredicate:(NSPredicate *)predicate
                     parent:(NSManagedObject *)parent
                  dataStack:(DATAStack *)dataStack
                 completion:(void (^)(NSArray *preprocessedArray))completion;

@end
