#import "NSManagedObject+Sync.h"

#import "NSEntityDescription+Sync.h"

@implementation NSManagedObject (Sync)

+ (NSManagedObject *)sync_safeObjectInContext:(NSManagedObjectContext *)context
                                   entityName:(NSString *)entityName
                                     remoteID:(id)remoteID
                                       parent:(NSManagedObject *)parent
                       parentRelationshipName:(NSString *)relationshipName
                                        error:(NSError **)error
{
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
                                  error:(NSError **)error
{
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

@end
