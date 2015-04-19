#import "Sync.h"

#import "DATAStack.h"
#import "DATAFilter.h"

#import "NSDictionary+ANDYSafeValue.h"
#import "NSManagedObject+HYPPropertyMapper.h"
#import "NSString+HYPNetworking.h"
#import "NSEntityDescription+Sync.h"
#import "NSManagedObject+Sync.h"

@interface NSManagedObject (SyncPrivate)

- (void)sync_processRelationshipsUsingDictionary:(NSDictionary *)objectDictionary
                                       andParent:(NSManagedObject *)parent
                                       dataStack:(DATAStack *)dataStack
                                           error:(NSError **)error;

- (void)sync_processToManyRelationship:(NSRelationshipDescription *)relationship
                       usingDictionary:(NSDictionary *)objectDictionary
                             andParent:(NSManagedObject *)parent
                             dataStack:(DATAStack *)dataStack;

- (void)sync_processToOneRelationship:(NSRelationshipDescription *)relationship
                      usingDictionary:(NSDictionary *)objectDictionary
                            andParent:(NSManagedObject *)parent
                            dataStack:(DATAStack *)dataStack
                                error:(NSError **)error;

@end

@implementation Sync

+ (void)changes:(NSArray *)changes
  inEntityNamed:(NSString *)entityName
      dataStack:(DATAStack *)dataStack
     completion:(void (^)(NSError *error))completion
{
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
     completion:(void (^)(NSError *error))completion
{
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
     completion:(void (^)(NSError *error))completion
{
    [dataStack performInNewBackgroundContext:^(NSManagedObjectContext *backgroundContext) {

        NSError *error = nil;
        NSManagedObject *safeParent = [parent sync_copyInContext:backgroundContext
                                       error:&error];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@", parent.entity.name, safeParent];

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
     completion:(void (^)(NSError *error))completion
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName
                                              inManagedObjectContext:context];

    NSString *localKey = [entity sync_localKey];
    NSParameterAssert(localKey);

    NSString *remoteKey = [entity sync_remoteKey];
    NSParameterAssert(remoteKey);

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

@implementation NSManagedObject (SyncPrivate)

- (void)sync_processRelationshipsUsingDictionary:(NSDictionary *)objectDictionary
                                       andParent:(NSManagedObject *)parent
                                       dataStack:(DATAStack *)dataStack
                                           error:(NSError **)error
{
    NSArray *relationships = [self sync_relationships];

    for (NSRelationshipDescription *relationship in relationships) {
        if (relationship.isToMany) {
            [self sync_processToManyRelationship:relationship
                                 usingDictionary:objectDictionary
                                       andParent:parent
                                       dataStack:dataStack];
        } else if (parent &&
                   [relationship.destinationEntity.name isEqualToString:parent.entity.name]) {
            [self setValue:parent
                    forKey:relationship.name];
        } else {
            NSError *error = nil;
            [self sync_processToOneRelationship:relationship
                                usingDictionary:objectDictionary
                                      andParent:parent
                                      dataStack:dataStack
                                          error:&error];
        }
    }
}

- (void)sync_processToManyRelationship:(NSRelationshipDescription *)relationship
                       usingDictionary:(NSDictionary *)objectDictionary
                             andParent:(NSManagedObject *)parent
                             dataStack:(DATAStack *)dataStack
{
    NSString *relationshipKey = relationship.userInfo[SyncCustomRemoteKey];
    NSString *relationshipName = (relationshipKey) ?: [relationship.name hyp_remoteString];
    NSString *childEntityName = relationship.destinationEntity.name;
    NSString *parentEntityName = parent.entity.name;
    NSString *inverseEntityName = relationship.inverseRelationship.name;
    BOOL inverseIsToMany = relationship.inverseRelationship.isToMany;
    BOOL hasValidManyToManyRelationship = (parent &&
                                           inverseIsToMany &&
                                           [parentEntityName isEqualToString:childEntityName]);
    NSArray *children = [objectDictionary andy_valueForKey:relationshipName];

    if (children) {
        NSPredicate *childPredicate;
        NSEntityDescription *entity = [NSEntityDescription entityForName:childEntityName
                                                  inManagedObjectContext:self.managedObjectContext];

        if (inverseIsToMany) {
            NSString *destinationRemoteKey = [entity sync_remoteKey];
            NSArray *childIDs = [children valueForKey:destinationRemoteKey];
            NSString *destinationLocalKey = [entity sync_localKey];
            if (childIDs.count == 1) {
                childPredicate = [NSPredicate predicateWithFormat:@"%K = %@", destinationLocalKey, [[children valueForKey:destinationRemoteKey] firstObject]];
            } else {
                childPredicate = [NSPredicate predicateWithFormat:@"ANY %K.%K = %@", relationshipName, destinationLocalKey, [children valueForKey:destinationRemoteKey]];
            }
        } else {
            childPredicate = [NSPredicate predicateWithFormat:@"%K = %@", inverseEntityName, self];
        }

        [Sync changes:children
        inEntityNamed:childEntityName
            predicate:childPredicate
               parent:self
            inContext:self.managedObjectContext
            dataStack:dataStack
           completion:nil];
    } else if (hasValidManyToManyRelationship) {
        NSMutableSet *relatedObjects = [self mutableSetValueForKey:relationshipName];
        [relatedObjects addObject:parent];
        [self setValue:relatedObjects forKey:relationshipName];
    }
}

- (void)sync_processToOneRelationship:(NSRelationshipDescription *)relationship
                      usingDictionary:(NSDictionary *)objectDictionary
                            andParent:(NSManagedObject *)parent
                            dataStack:(DATAStack *)dataStack
                                error:(NSError **)error
{
    NSString *relationshipKey = [[relationship userInfo] valueForKey:SyncCustomRemoteKey];
    NSString *relationshipName = (relationshipKey) ?: [relationship.name hyp_remoteString];
    NSString *entityName = relationship.destinationEntity.name;
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName
                                              inManagedObjectContext:self.managedObjectContext];
    NSDictionary *filteredObjectDictionary = [objectDictionary andy_valueForKey:relationshipName];
    if (filteredObjectDictionary) {
        NSError *error = nil;
        NSString *remoteKey = [entity sync_remoteKey];
        NSManagedObject *object = [NSManagedObject sync_safeObjectInContext:self.managedObjectContext
                                                                 entityName:entityName
                                                                   remoteID:[filteredObjectDictionary andy_valueForKey:remoteKey]
                                                                     parent:self
                                                     parentRelationshipName:relationship.name
                                                                      error:&error];

        if (!object) {
            object = [NSEntityDescription insertNewObjectForEntityForName:entityName
                                                   inManagedObjectContext:self.managedObjectContext];
        }

        [object hyp_fillWithDictionary:filteredObjectDictionary];
        [object sync_processRelationshipsUsingDictionary:filteredObjectDictionary
                                               andParent:self
                                               dataStack:dataStack
                                                   error:&error];

        [self setValue:object
                forKey:relationship.name];
    }
}

@end
