@import CoreData;

#import "PropertyMapper.h"

static NSString * const PropertyMapperDestroyKey = @"destroy";

/**
 Internal helpers, not meant to be included in the public APIs.
 */
@interface NSManagedObject (PropertyMapperHelpers)

- (id)valueForAttributeDescription:(NSAttributeDescription *)attributeDescription
                     dateFormatter:(NSDateFormatter *)dateFormatter
                  relationshipType:(PropertyMapperRelationshipType)relationshipType;

- (NSAttributeDescription *)attributeDescriptionForRemoteKey:(NSString *)remoteKey;

- (NSAttributeDescription *)attributeDescriptionForRemoteKey:(NSString *)remoteKey
                                         usingInflectionType:(PropertyMapperInflectionType)inflectionType;

- (NSArray *)attributeDescriptionsForRemoteKeyPath:(NSString *)key;

- (id)valueForAttributeDescription:(id)attributeDescription
                  usingRemoteValue:(id)removeValue;

- (NSString *)remoteKeyForAttributeDescription:(NSAttributeDescription *)attributeDescription;

- (NSString *)remoteKeyForAttributeDescription:(NSAttributeDescription *)attributeDescription
                                inflectionType:(PropertyMapperInflectionType)inflectionType;

- (NSString *)remoteKeyForAttributeDescription:(NSAttributeDescription *)attributeDescription
                         usingRelationshipType:(PropertyMapperRelationshipType)relationshipType;

- (NSString *)remoteKeyForAttributeDescription:(NSAttributeDescription *)attributeDescription
                         usingRelationshipType:(PropertyMapperRelationshipType)relationshipType
                                inflectionType:(PropertyMapperInflectionType)inflectionType;

+ (NSArray *)reservedAttributes;

- (NSString *)prefixedAttribute:(NSString *)attribute
            usingInflectionType:(PropertyMapperInflectionType)inflectionType;

@end
