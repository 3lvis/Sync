#import "NSArray+Sync.h"

#import "NSManagedObject+HYPPropertyMapper.h"

@implementation NSArray (Sync)

- (NSArray *)preprocessForEntity:(NSEntityDescription *)entity
                  usingPredicate:(NSPredicate *)predicate
                       dataStack:(DATAStack *)dataStack {
    NSMutableArray *filteredChanges = [NSMutableArray new];

    if ([predicate isKindOfClass:[NSComparisonPredicate class]]) {
        NSComparisonPredicate *castedPredicate = (NSComparisonPredicate *)predicate;
        NSExpression *rightExpression = castedPredicate.rightExpression;
        id rightValue = [rightExpression constantValue];
        BOOL rightValueCanBeCompared = (rightValue &&
                                        ([rightValue isKindOfClass:[NSDate class]] ||
                                         [rightValue isKindOfClass:[NSNumber class]] ||
                                         [rightValue isKindOfClass:[NSString class]]));
        if (rightValueCanBeCompared) {
            NSMutableArray *objectChanges = [NSMutableArray new];
            for (NSDictionary *change in self) {
                NSManagedObject *object = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:dataStack.disposableMainContext];
                [object hyp_fillWithDictionary:change];
                [objectChanges addObject:object];
            }

            NSArray *filteredArray = [objectChanges filteredArrayUsingPredicate:predicate];
            for (NSManagedObject *filteredObject in filteredArray) {
                [filteredChanges addObject:[filteredObject hyp_dictionary]];
            }
        }
    }

    return [filteredChanges copy];
}

@end
