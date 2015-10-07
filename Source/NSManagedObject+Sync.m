#import "NSManagedObject+Sync.h"

#import "DATAStack.h"
#import "Sync.h"

#import "NSDictionary+ANDYSafeValue.h"
#import "NSEntityDescription+SYNCPrimaryKey.h"
#import "NSManagedObject+HYPPropertyMapper.h"
#import "NSString+HYPNetworking.h"
#import "NSEntityDescription+Sync.h"

@implementation NSManagedObject (Sync)

+ (NSManagedObject *)sync_safeObjectInContext:(NSManagedObjectContext *)context
                                   entityName:(NSString *)entityName
                                     remoteID:(id)remoteID
                                       parent:(NSManagedObject *)parent
                       parentRelationshipName:(NSString *)relationshipName
                                        error:(NSError **)error {
    if(!remoteID) {
        return [parent valueForKey:relationshipName];
    }

    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName
                                              inManagedObjectContext:context];

    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:entityName];
    NSString *localKey = [entity sync_localKey];
    request.predicate = [NSPredicate predicateWithFormat:@"%K = %@", localKey, remoteID];
    NSArray *objects = [context executeFetchRequest:request error:error];

    return objects.firstObject;
}

- (NSManagedObject *)sync_copyInContext:(NSManagedObjectContext *)context
                                  error:(NSError **)error {
    NSEntityDescription *entity = [NSEntityDescription entityForName:self.entity.name
                                              inManagedObjectContext:context];
    NSString *localKey = [entity sync_localKey];
    NSString *remoteID = [self valueForKey:localKey];

    return [NSManagedObject sync_safeObjectInContext:context
                                          entityName:self.entity.name
                                            remoteID:remoteID
                                              parent:nil
                              parentRelationshipName:nil
                                               error:error];
}

- (void)sync_processRelationshipsUsingDictionary:(NSDictionary *)objectDictionary
                                       andParent:(NSManagedObject *)parent
                                       dataStack:(DATAStack *)dataStack
                                           error:(NSError **)error {
    NSArray *relationships = [self.entity sync_relationships];

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
                             dataStack:(DATAStack *)dataStack {
    NSString *relationshipKey = relationship.userInfo[SYNCCustomRemoteKey];
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
            if (childIDs.count > 0) {
                childPredicate = [NSPredicate predicateWithFormat:@"ANY %K IN %@", destinationLocalKey, [children valueForKey:destinationRemoteKey]];
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
        NSMutableSet *relatedObjects = [self mutableSetValueForKey:relationship.name];
        [relatedObjects addObject:parent];
        [self setValue:relatedObjects forKey:relationship.name];
    }
}

- (void)sync_processToOneRelationship:(NSRelationshipDescription *)relationship
                      usingDictionary:(NSDictionary *)objectDictionary
                            andParent:(NSManagedObject *)parent
                            dataStack:(DATAStack *)dataStack
                                error:(NSError **)error {
    NSString *relationshipKey = [[relationship userInfo] valueForKey:SYNCCustomRemoteKey];
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
