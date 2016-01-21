@import CoreData;

@interface NSEntityDescription (Sync)

- (nonnull NSArray<NSRelationshipDescription *> *)sync_relationships;

- (nullable NSRelationshipDescription *)sync_parentEntity;

@end
