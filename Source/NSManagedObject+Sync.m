#import "NSManagedObject+Sync.h"

@import DATAStack;

#import "NSDictionary+ANDYSafeValue.h"
#import "NSEntityDescription+SYNCPrimaryKey.h"
#import "NSManagedObject+HYPPropertyMapper.h"
#import "NSString+HYPNetworking.h"
#import "NSEntityDescription+Sync.h"

@implementation NSManagedObject (Sync)

- (void)sync_processRelationshipsUsingDictionary:(NSDictionary *)objectDictionary
                                       andParent:(NSManagedObject *)parent
                                       dataStack:(DATAStack *)dataStack
                                           error:(NSError **)error {
    NSArray *relationships = [self.entity sync_relationships];

    for (NSRelationshipDescription *relationship in relationships) {
        NSEntityDescription *entity = [NSEntityDescription entityForName:relationship.entity.name inManagedObjectContext:self.managedObjectContext];
        NSArray<NSRelationshipDescription *> *relationships = [entity relationshipsWithDestinationEntity:relationship.destinationEntity];
        NSString *keyName = [[relationships.firstObject.name hyp_remoteString] stringByAppendingString:@"_id"];
        if (relationship.isToMany) {
            [self sync_processToManyRelationship:relationship
                                 usingDictionary:objectDictionary
                                       andParent:parent
                                       dataStack:dataStack];
        } else if (parent &&
                   [relationship.destinationEntity.name isEqualToString:parent.entity.name]) {
            id currentParent = [self valueForKey:relationship.name];
            if (![currentParent isEqual:parent]) {
                [self setValue:parent
                        forKey:relationship.name];
            }
        } else if ([objectDictionary objectForKey:keyName]) {
            NSError *error = nil;
            [self sync_processIDRelationship:relationship
                                    remoteID:[objectDictionary objectForKey:keyName]
                                   andParent:parent
                                   dataStack:dataStack
                                       error:&error];
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

@end
