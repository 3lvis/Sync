#import "Sync.h"

#import "DATAStack.h"
#import "DATAFilter.h"

#import "NSDictionary+ANDYSafeValue.h"
#import "NSManagedObject+HYPPropertyMapper.h"
#import "NSString+HYPNetworking.h"
#import "NSEntityDescription+SYNCPrimaryKey.h"
#import "NSManagedObject+Sync.h"
#import "NSEntityDescription+Sync.h"

@implementation Sync

+ (void)changes:(NSArray *)changes
  inEntityNamed:(NSString *)entityName
      dataStack:(DATAStack *)dataStack
     completion:(void (^)(NSError *error))completion {
    [self changes:changes
    inEntityNamed:entityName
        predicate:nil
        dataStack:dataStack
       completion:completion];
}

+ (void)changes:(NSArray *)changes
  inEntityNamed:(NSString *)entityName
      predicate:(NSPredicate *)predicate
      dataStack:(DATAStack *)dataStack
     completion:(void (^)(NSError *error))completion {
    [dataStack performInNewBackgroundContext:^(NSManagedObjectContext *backgroundContext) {

        [self changes:changes
        inEntityNamed:entityName
            predicate:predicate
               parent:nil
            inContext:backgroundContext
            dataStack:dataStack
           completion:completion];
    }];
}

+ (void)changes:(NSArray *)changes
  inEntityNamed:(NSString *)entityName
         parent:(NSManagedObject *)parent
      dataStack:(DATAStack *)dataStack
     completion:(void (^)(NSError *error))completion {
    [dataStack performInNewBackgroundContext:^(NSManagedObjectContext *backgroundContext) {

        NSError *error = nil;
        NSManagedObject *safeParent = [parent sync_copyInContext:backgroundContext
                                                           error:&error];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@", [parent.entity.name lowercaseString], safeParent];

        [self changes:changes
        inEntityNamed:entityName
            predicate:predicate
               parent:safeParent
            inContext:backgroundContext
            dataStack:dataStack
           completion:completion];
    }];
}

+ (void)changes:(NSArray *)changes
  inEntityNamed:(NSString *)entityName
      predicate:(NSPredicate *)predicate
         parent:(NSManagedObject *)parent
      inContext:(NSManagedObjectContext *)context
      dataStack:(DATAStack *)dataStack
     completion:(void (^)(NSError *error))completion {
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName
                                              inManagedObjectContext:context];

    NSString *localKey = [entity sync_localKey];
    NSParameterAssert(localKey);

    NSString *remoteKey = [entity sync_remoteKey];
    NSParameterAssert(remoteKey);

    BOOL shouldLookForParent = (!parent && !predicate);
    if (shouldLookForParent) {
        NSRelationshipDescription *parentEntity = [entity sync_parentEntity];
        if (parentEntity) {
            predicate = [NSPredicate predicateWithFormat:@"%K = nil", parentEntity.name];
        }
    }

    if (predicate) {
        NSArray *processedChanges = [self preprocessRemoteChanges:changes forEntity:entity usingPredicate:predicate dataStack:dataStack];
        if (processedChanges.count > 0) {
            changes = processedChanges;
        }
    }

    [DATAFilter changes:changes
          inEntityNamed:entityName
               localKey:localKey
              remoteKey:remoteKey
                context:context
              predicate:predicate
               inserted:^(NSDictionary *objectJSON) {
                   NSError *error = nil;
                   NSManagedObject *created = [NSEntityDescription insertNewObjectForEntityForName:entityName
                                                                            inManagedObjectContext:context];
                   [created hyp_fillWithDictionary:objectJSON];
                   [created sync_processRelationshipsUsingDictionary:objectJSON
                                                           andParent:parent
                                                           dataStack:dataStack
                                                               error:&error];
               } updated:^(NSDictionary *objectJSON, NSManagedObject *updatedObject) {
                   NSError *error = nil;
                   [updatedObject hyp_fillWithDictionary:objectJSON];
                   [updatedObject sync_processRelationshipsUsingDictionary:objectJSON
                                                                 andParent:parent
                                                                 dataStack:dataStack
                                                                     error:&error];
               }];

    NSError *error = nil;
    [context save:&error];

    [dataStack persistWithCompletion:^{
        if (completion) {
            completion(error);
        }
    }];
}

+ (NSArray *)preprocessRemoteChanges:(NSArray *)changes forEntity:(NSEntityDescription *)entity usingPredicate:(NSPredicate *)predicate dataStack:(DATAStack *)dataStack {
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
            for (NSDictionary *change in changes) {
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
