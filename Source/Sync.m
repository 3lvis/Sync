#import "Sync.h"

#import "NSDictionary+ANDYSafeValue.h"
#import "NSManagedObject+HYPPropertyMapper.h"
#import "NSManagedObject+ANDYMapChanges.h"
#import "DATAStack.h"

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

+ (void)processChanges:(NSArray *)changes
       usingEntityName:(NSString *)entityName
             dataStack:(DATAStack *)dataStack
            completion:(void (^)(NSError *error))completion
{
    [self processChanges:changes
         usingEntityName:entityName
               predicate:nil
               dataStack:dataStack
              completion:completion];
}

+ (void)processChanges:(NSArray *)changes
       usingEntityName:(NSString *)entityName
             predicate:(NSPredicate *)predicate
             dataStack:(DATAStack *)dataStack
            completion:(void (^)(NSError *error))completion
{
    [dataStack performInNewBackgroundContext:^(NSManagedObjectContext *backgroundContext) {

        [self processChanges:changes
             usingEntityName:entityName
                   predicate:predicate
                      parent:nil
                   inContext:backgroundContext
                   dataStack:dataStack
                  completion:completion];
    }];
}

+ (void)processChanges:(NSArray *)changes
       usingEntityName:(NSString *)entityName
                parent:(NSManagedObject *)parent
             dataStack:(DATAStack *)dataStack
            completion:(void (^)(NSError *error))completion
{
    [dataStack performInNewBackgroundContext:^(NSManagedObjectContext *backgroundContext) {

        NSManagedObject *safeParent = [parent sync_copyInContext:backgroundContext];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@", parent.entity.name, safeParent];

        [self processChanges:changes
             usingEntityName:entityName
                   predicate:predicate
                      parent:safeParent
                   inContext:backgroundContext
                   dataStack:dataStack
                  completion:completion];
    }];
}

+ (void)processChanges:(NSArray *)changes
       usingEntityName:(NSString *)entityName
             predicate:(NSPredicate *)predicate
                parent:(NSManagedObject *)parent
             inContext:(NSManagedObjectContext *)context
             dataStack:(DATAStack *)dataStack
            completion:(void (^)(NSError *error))completion
{
    [NSManagedObject andy_mapChanges:changes
                      usingPredicate:predicate
                           inContext:context
                       forEntityName:entityName
                            inserted:^(NSDictionary *objectDict) {

                                NSManagedObject *created = [NSEntityDescription insertNewObjectForEntityForName:entityName
                                                                                         inManagedObjectContext:context];
                                [created hyp_fillWithDictionary:objectDict];
                                [created sync_processRelationshipsUsingDictionary:objectDict andParent:parent dataStack:dataStack];

                            } updated:^(NSDictionary *objectDict, NSManagedObject *object) {

                                [object hyp_fillWithDictionary:objectDict];
                                [object sync_processRelationshipsUsingDictionary:objectDict andParent:parent dataStack:dataStack];

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
    NSError *error = nil;
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:entityName];
    NSString *localKey = @"remoteID";
    request.predicate = [NSPredicate predicateWithFormat:@"%K = %@", localKey, remoteID];

    NSArray *objects = [context executeFetchRequest:request error:&error];
    if (error) NSLog(@"parentError: %@", error);
    return [objects firstObject];
}

@end

@implementation NSManagedObject (Sync)

- (NSManagedObject *)sync_copyInContext:(NSManagedObjectContext *)context
{
    NSString *localKey = @"remoteID";
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
            if (parent && [relationship.destinationEntity.name isEqualToString: parent.entity.name]) {
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
    NSString *childEntityName = relationship.destinationEntity.name;
    NSString *parentEntityName = parent.entity.name;
    NSString *inverseEntityName = relationship.inverseRelationship.name;
    NSString *relationshipName = relationship.name;
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

    if (inverseIsToMany) {
        NSArray *childIDs = [childs valueForKey:@"id"];
        NSString *destinationKey = @"remoteID";
        if (childIDs.count == 1) {
            childPredicate = [NSPredicate predicateWithFormat:@"%K = %@", destinationKey, [[childs valueForKey:@"id"] firstObject]];
        } else {
            childPredicate = [NSPredicate predicateWithFormat:@"ANY %K.%K = %@", relationshipName, destinationKey, [childs valueForKey:@"id"]];
        }
    } else {
        childPredicate = [NSPredicate predicateWithFormat:@"%K = %@", inverseEntityName, self];
    }

    [Sync processChanges:childs
         usingEntityName:childEntityName
               predicate:childPredicate
                  parent:self
               inContext:self.managedObjectContext
               dataStack:dataStack
              completion:nil];
}

- (void)sync_processToOneRelationship:(NSRelationshipDescription *)relationship
                      usingDictionary:(NSDictionary *)objectDict
{
    NSString *entityName = [relationship.name capitalizedString];
    NSDictionary *filteredObjectDict = [objectDict andy_valueForKey:relationship.name];
    if (!filteredObjectDict) return;

    NSManagedObject *object = [Sync safeObjectInContext:self.managedObjectContext
                                             entityName:entityName
                                               remoteID:[filteredObjectDict andy_valueForKey:@"id"]];
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
