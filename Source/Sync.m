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

@end
