#import "NSEntityDescription+Sync.h"

@implementation NSEntityDescription (Sync)

- (NSArray *)sync_relationships {
    NSMutableArray *relationships = [NSMutableArray array];

    for (id propertyDescription in [self properties]) {
        if ([propertyDescription isKindOfClass:[NSRelationshipDescription class]]) {
            [relationships addObject:propertyDescription];
        }
    }

    return relationships;
}

- (NSRelationshipDescription *)sync_parentEntity {
    NSArray *relationships = [self sync_relationships];
    NSRelationshipDescription *foundParentEntity = nil;
    for (NSRelationshipDescription *relationship in relationships) {
        BOOL isParent = ([relationship.destinationEntity.name isEqualToString:self.name] &&
                         !relationship.isToMany);
        if (isParent) {
            foundParentEntity = relationship;
        }
    }

    return foundParentEntity;
}

@end
