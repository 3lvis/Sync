#import "NSArray+Sync.h"

#import "NSManagedObject+HYPPropertyMapper.h"
#import "NSManagedObject+Sync.h"

@implementation NSArray (Sync)

- (NSArray *)preprocessForEntityNamed:(NSString *)entityName
                       usingPredicate:(NSPredicate *)predicate
                               parent:(NSManagedObject *)parent
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
            NSEntityDescription *entity = [NSEntityDescription entityForName:entityName
                                                      inManagedObjectContext:dataStack.disposableMainContext];
            for (NSDictionary *change in self) {
                NSManagedObject *object = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:dataStack.disposableMainContext];
                NSError *error = nil;
                [object hyp_fillWithDictionary:change];
                [object sync_processRelationshipsUsingDictionary:change
                                                       andParent:parent
                                                       dataStack:dataStack
                                                           error:&error];
                [objectChanges addObject:object];
            }

            NSArray *filteredArray = [objectChanges filteredArrayUsingPredicate:predicate];
            for (NSManagedObject *filteredObject in filteredArray) {
                [filteredChanges addObject:[filteredObject hyp_dictionaryUsingRelationshipType:HYPPropertyMapperRelationshipTypeArray]];
            }
        }
    }

    return [filteredChanges copy];
}

@end
