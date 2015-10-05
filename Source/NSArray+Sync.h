@import Foundation;
@import CoreData;

#import "DATAStack.h"

@interface NSArray (Sync)

- (NSArray *)preprocessForEntity:(NSEntityDescription *)entity
                  usingPredicate:(NSPredicate *)predicate
                       dataStack:(DATAStack *)dataStack;

@end
