@import CoreData;

#import "PropertyMapper.h"

/**
 Internal helpers, not meant to be included in the public APIs.
 */
@interface NSManagedObject (PropertyMapperHelpers)

- (id)valueForAttributeDescription:(NSAttributeDescription *)attributeDescription
                     dateFormatter:(NSDateFormatter *)dateFormatter
                  relationshipType:(SyncPropertyMapperRelationshipType)relationshipType;

- (NSAttributeDescription *)attributeDescriptionForRemoteKey:(NSString *)remoteKey;

- (NSAttributeDescription *)attributeDescriptionForRemoteKey:(NSString *)remoteKey
                                         usingInflectionType:(SyncPropertyMapperInflectionType)inflectionType;

- (NSArray *)attributeDescriptionsForRemoteKeyPath:(NSString *)key;

- (id)valueForAttributeDescription:(id)attributeDescription
                  usingRemoteValue:(id)removeValue;

- (NSString *)remoteKeyForAttributeDescription:(NSAttributeDescription *)attributeDescription;

- (NSString *)remoteKeyForAttributeDescription:(NSAttributeDescription *)attributeDescription
                                inflectionType:(SyncPropertyMapperInflectionType)inflectionType;

- (NSString *)remoteKeyForAttributeDescription:(NSAttributeDescription *)attributeDescription
                         usingRelationshipType:(SyncPropertyMapperRelationshipType)relationshipType;

- (NSString *)remoteKeyForAttributeDescription:(NSAttributeDescription *)attributeDescription
                         usingRelationshipType:(SyncPropertyMapperRelationshipType)relationshipType
                                inflectionType:(SyncPropertyMapperInflectionType)inflectionType;

+ (NSArray *)reservedAttributes;

- (NSString *)prefixedAttribute:(NSString *)attribute
            usingInflectionType:(SyncPropertyMapperInflectionType)inflectionType;

@end
