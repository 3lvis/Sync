@import CoreData;

@interface NSEntityDescription (Sync)

- (nonnull NSArray *)sync_relationships;

- (nullable NSRelationshipDescription *)sync_parentEntity;

@end
