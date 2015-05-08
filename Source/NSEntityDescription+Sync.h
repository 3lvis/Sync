@import CoreData;

@interface NSEntityDescription (Sync)

- (NSArray *)sync_relationships;

- (NSRelationshipDescription *)sync_parentEntity;

@end
