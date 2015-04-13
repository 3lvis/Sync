#import "Sync.h"

#import "DATAStack.h"

#import "NSDictionary+ANDYSafeValue.h"
#import "NSManagedObject+HYPPropertyMapper.h"
#import "DATAFilter.h"
#import "NSString+HYPNetworking.h"

static NSString * const SyncDefaultLocalPrimaryKey = @"remoteID";
static NSString * const SyncDefaultRemotePrimaryKey = @"id";

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
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName
                                              inManagedObjectContext:context];

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

    if (error) {
        NSLog(@"Sync (error while saving %@): %@", entityName, [error description]);
    }

    [dataStack persistWithCompletion:^{
        if (completion) {
            completion(error);
        }
    }];
}

+ (NSManagedObject *)safeObjectInContext:(NSManagedObjectContext *)context
                              entityName:(NSString *)entityName
                                remoteID:(id)remoteID
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName
                                              inManagedObjectContext:context];
    NSError *error = nil;
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:entityName];
    NSString *localKey = [entity sync_localKey];
    request.predicate = [NSPredicate predicateWithFormat:@"%K = %@", localKey, remoteID];
    NSArray *objects = [context executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"parentError: %@", error);
    }

    return objects.firstObject;
}

@end

@implementation NSManagedObject (Sync)

- (NSManagedObject *)sync_copyInContext:(NSManagedObjectContext *)context
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:self.entity.name
                                              inManagedObjectContext:context];
    NSString *localKey = [entity sync_localKey];
    NSString *remoteID = [self valueForKey:localKey];

    return [Sync safeObjectInContext:context
                          entityName:self.entity.name
                            remoteID:remoteID];
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
            [self sync_processToManyRelationship:relationship
                                 usingDictionary:objectDict
                                       andParent:parent dataStack:dataStack];
        } else if (parent &&
                   [relationship.destinationEntity.name isEqualToString:parent.entity.name]) {
            [self setValue:parent
                    forKey:relationship.name];
        } else {
            [self sync_processToOneRelationship:relationship
                                usingDictionary:objectDict];
        }
    }
}

- (void)sync_processToManyRelationship:(NSRelationshipDescription *)relationship
                       usingDictionary:(NSDictionary *)objectDict
                             andParent:(NSManagedObject *)parent
                             dataStack:(DATAStack *)dataStack
{
    NSString *relationshipKey = relationship.userInfo[SyncCustomRemoteKey];
    NSString *relationshipName = (relationshipKey) ?: relationship.name;
    NSString *childEntityName = relationship.destinationEntity.name;
    NSString *parentEntityName = parent.entity.name;
    NSString *inverseEntityName = relationship.inverseRelationship.name;
    BOOL inverseIsToMany = relationship.inverseRelationship.isToMany;
    BOOL hasValidManyToManyRelationship = (parent &&
                                           inverseIsToMany &&
                                           [parentEntityName isEqualToString:childEntityName]);
    NSArray *children = [objectDict andy_valueForKey:relationshipName];

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
                      usingDictionary:(NSDictionary *)objectDict
{
    NSString *relationshipKey = [[relationship userInfo] valueForKey:SyncCustomRemoteKey];
    NSString *relationshipName = (relationshipKey) ?: relationship.name;
    NSString *entityName = relationship.destinationEntity.name;
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName
                                              inManagedObjectContext:self.managedObjectContext];
    NSDictionary *filteredObjectDict = [objectDict andy_valueForKey:relationshipName];
    if (filteredObjectDict) {
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

        [self setValue:object
                forKey:relationship.name];
    }
}

@end

@implementation NSEntityDescription (Sync)

- (NSAttributeDescription *)sync_primaryAttribute
{
    __block NSAttributeDescription *primaryAttribute = nil;
    
    [self.propertiesByName enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSAttributeDescription *attributeDescription, BOOL *stop) {
        NSString *isPrimaryKey = attributeDescription.userInfo[SyncCustomPrimaryKey];
        BOOL hasCustomPrimaryKey = (isPrimaryKey &&
                                    [isPrimaryKey isEqualToString:@"YES"]);
        
        if (hasCustomPrimaryKey) {
            primaryAttribute = attributeDescription;
            *stop = YES;
        }
        
        if ([key isEqualToString:SyncDefaultLocalPrimaryKey]) {
            primaryAttribute = attributeDescription;
        }
    }];
    
    return primaryAttribute;
}

- (NSString *)sync_localKey
{
    NSString *localKey;
    NSAttributeDescription *primaryAttribute = [self sync_primaryAttribute];
    
    localKey = primaryAttribute.name;

    return localKey;
}

- (NSString *)sync_remoteKey
{
    NSAttributeDescription *primaryAttribute = [self sync_primaryAttribute];
    NSString *remoteKey = primaryAttribute.userInfo[HYPPropertyMapperCustomRemoteKey];
    
    if (!remoteKey) {
        if ([primaryAttribute.name isEqualToString:SyncDefaultLocalPrimaryKey]) {
            remoteKey = SyncDefaultRemotePrimaryKey;
        } else {
            remoteKey = [primaryAttribute.name hyp_remoteString];
        }
        
    }

    return remoteKey;
}

@end
