#import "Sync.h"

#import "DATAStack.h"

#import "NSDictionary+ANDYSafeValue.h"
#import "NSManagedObject+HYPPropertyMapper.h"
#import "DATAFilter.h"
#import "NSString+HYPNetworking.h"

@interface NSEntityDescription (Sync)

- (NSString *)sync_remoteKey;
- (NSString *)sync_localKey;

@end

@interface NSManagedObject (Sync)

- (NSManagedObject *)sync_copyInContext:(NSManagedObjectContext *)context;

- (NSArray *)sync_relationships;

- (void)sync_processRelationshipsUsingDictionary:(NSDictionary *)objectDict
                                       andParent:(NSManagedObject *)parent
                                       dataStack:(DATAStack *)dataStack;

- (void)sync_processToManyRelationship:(NSRelationshipDescription *)relationship
                       usingDictionary:(NSDictionary *)objectDict
                             andParent:(NSManagedObject *)parent
                             dataStack:(DATAStack *)dataStack;

- (void)sync_processToOneRelationship:(NSRelationshipDescription *)relationship
                      usingDictionary:(NSDictionary *)objectDict;

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

        NSManagedObject *safeParent = [parent sync_copyInContext:backgroundContext];
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
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:context];

    [DATAFilter changes:changes
          inEntityNamed:entityName
               localKey:[entity sync_localKey]
              remoteKey:[entity sync_remoteKey]
                context:context
              predicate:predicate
               inserted:^(NSDictionary *objectJSON) {
                   NSManagedObject *created = [NSEntityDescription insertNewObjectForEntityForName:entityName
                                                                            inManagedObjectContext:context];
                   [created hyp_fillWithDictionary:objectJSON];
                   [created sync_processRelationshipsUsingDictionary:objectJSON
                                                           andParent:parent
                                                           dataStack:dataStack];
               } updated:^(NSDictionary *objectJSON, NSManagedObject *updatedObject) {
                   [updatedObject hyp_fillWithDictionary:objectJSON];
                   [updatedObject sync_processRelationshipsUsingDictionary:objectJSON
                                                                 andParent:parent
                                                                 dataStack:dataStack];
               }];

    NSError *error = nil;
    [context save:&error];
    if (error) NSLog(@"Sync (error while saving %@): %@", entityName, [error description]);

    [dataStack persistWithCompletion:^{
        if (completion) completion(error);
    }];
}

+ (NSManagedObject *)safeObjectInContext:(NSManagedObjectContext *)context
                              entityName:(NSString *)entityName
                                remoteID:(id)remoteID
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:context];
    NSError *error = nil;
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:entityName];
    NSString *localKey = [entity sync_localKey];
    request.predicate = [NSPredicate predicateWithFormat:@"%K = %@", localKey, remoteID];

    NSArray *objects = [context executeFetchRequest:request error:&error];
    if (error) NSLog(@"parentError: %@", error);
    return [objects firstObject];
}

@end

@implementation NSManagedObject (Sync)

- (NSManagedObject *)sync_copyInContext:(NSManagedObjectContext *)context
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:self.entity.name inManagedObjectContext:context];
    NSString *localKey = [entity sync_localKey];
    NSString *remoteID = [self valueForKey:localKey];

    return [Sync safeObjectInContext:context entityName:self.entity.name remoteID:remoteID];
}

- (NSArray *)sync_relationships
{
    NSMutableArray *relationships = [NSMutableArray array];

    for (id propertyDescription in [self.entity properties]) {

        if ([propertyDescription isKindOfClass:[NSRelationshipDescription class]]) {
            [relationships addObject:propertyDescription];
        }
    }

    return relationships;
}

- (void)sync_processRelationshipsUsingDictionary:(NSDictionary *)objectDict
                                       andParent:(NSManagedObject *)parent
                                       dataStack:(DATAStack *)dataStack
{
    NSArray *relationships = [self sync_relationships];

    for (NSRelationshipDescription *relationship in relationships) {
        if (relationship.isToMany) {
            [self sync_processToManyRelationship:relationship usingDictionary:objectDict andParent:parent dataStack:dataStack];
        } else {
            if (parent && [relationship.destinationEntity.name isEqualToString:parent.entity.name]) {
                [self setValue:parent forKey:relationship.name];
            } else {
                [self sync_processToOneRelationship:relationship usingDictionary:objectDict];
            }
        }
    }
}

- (void)sync_processToManyRelationship:(NSRelationshipDescription *)relationship
                       usingDictionary:(NSDictionary *)objectDict
                             andParent:(NSManagedObject *)parent
                             dataStack:(DATAStack *)dataStack
{
    NSString *relationshipKey = [[relationship userInfo] valueForKey:SyncCustomRemoteKey];

    NSString *relationshipName = (relationshipKey) ?: relationship.name;

    NSString *childEntityName = relationship.destinationEntity.name;
    NSString *parentEntityName = parent.entity.name;
    NSString *inverseEntityName = relationship.inverseRelationship.name;
    BOOL inverseIsToMany = relationship.inverseRelationship.isToMany;
    NSArray *childs = [objectDict andy_valueForKey:relationshipName];

    if (!childs) {
        BOOL hasValidManyToManyRelationship = (parent &&
                                               inverseIsToMany &&
                                               [parentEntityName isEqualToString:childEntityName]);
        if (hasValidManyToManyRelationship) {
            NSMutableSet *relatedObjects = [self mutableSetValueForKey:relationshipName];
            [relatedObjects addObject:parent];
            [self setValue:relatedObjects forKey:relationshipName];
        }

        return;
    }

    NSPredicate *childPredicate;
    NSEntityDescription *entity = [NSEntityDescription entityForName:childEntityName inManagedObjectContext:self.managedObjectContext];

    if (inverseIsToMany) {
        NSString *destinationRemoteKey = [entity sync_remoteKey];
        NSArray *childIDs = [childs valueForKey:destinationRemoteKey];
        NSString *destinationLocalKey = [entity sync_localKey];
        if (childIDs.count == 1) {
            childPredicate = [NSPredicate predicateWithFormat:@"%K = %@", destinationLocalKey, [[childs valueForKey:destinationRemoteKey] firstObject]];
        } else {
            childPredicate = [NSPredicate predicateWithFormat:@"ANY %K.%K = %@", relationshipName, destinationLocalKey, [childs valueForKey:destinationRemoteKey]];
        }
    } else {
        childPredicate = [NSPredicate predicateWithFormat:@"%K = %@", inverseEntityName, self];
    }

    [Sync changes:childs
    inEntityNamed:childEntityName
        predicate:childPredicate
           parent:self
        inContext:self.managedObjectContext
        dataStack:dataStack
       completion:nil];
}

- (void)sync_processToOneRelationship:(NSRelationshipDescription *)relationship
                      usingDictionary:(NSDictionary *)objectDict
{
    NSString *entityName = relationship.destinationEntity.name;
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self.managedObjectContext];
    NSDictionary *filteredObjectDict = [objectDict andy_valueForKey:relationship.name];
    if (!filteredObjectDict) return;

    NSString *remoteKey = [entity sync_remoteKey];
    NSManagedObject *object = [Sync safeObjectInContext:self.managedObjectContext
                                             entityName:entityName
                                               remoteID:[filteredObjectDict andy_valueForKey:remoteKey]];
    if (object) {
        [object hyp_fillWithDictionary:filteredObjectDict];
    } else {
        object = [NSEntityDescription insertNewObjectForEntityForName:entityName
                                               inManagedObjectContext:self.managedObjectContext];
        [object hyp_fillWithDictionary:filteredObjectDict];
    }

    [self setValue:object forKey:relationship.name];
}

@end

@implementation NSEntityDescription (Sync)

- (NSString *)sync_localKey
{
    __block NSString *localKey;
    [self.propertiesByName enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSAttributeDescription *attributeDescription, BOOL *stop) {
        NSString *isPrimaryKey = attributeDescription.userInfo[SyncCustomPrimaryKey];
        BOOL hasCustomPrimaryKey = (isPrimaryKey &&
                                    [isPrimaryKey isEqualToString:@"YES"]);
        if (hasCustomPrimaryKey) {
            localKey = key;
        }
    }];

    if (!localKey) {
        localKey = @"remoteID";
    }

    return localKey;
}

- (NSString *)sync_remoteKey
{
    NSString *remoteKey;
    NSString *localKey = [self sync_localKey];
    if ([localKey isEqualToString:@"remoteID"]) {
        remoteKey = @"id";
    } else {
        remoteKey = [localKey hyp_remoteString];
    }

    return remoteKey;
}

@end
