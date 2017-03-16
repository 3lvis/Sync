@import CoreData;

#import "SYNCPropertyMapper.h"

static NSString * const SYNCPropertyMapperDestroyKey = @"destroy";
static NSString * const SYNCPropertyMapperCustomValueTransformerKey = @"hyper.valueTransformer";
static NSString * const SYNCPropertyMapperCustomRemoteKey = @"hyper.remoteKey";
static NSString * const SYNCPropertyMapperNonExportableKey = @"hyper.nonExportable";

/**
 Internal helpers, not meant to be included in the public APIs.
 */
@interface NSManagedObject (SYNCPropertyMapperHelpers)

- (id)valueForAttributeDescription:(NSAttributeDescription *)attributeDescription
                     dateFormatter:(NSDateFormatter *)dateFormatter
                  relationshipType:(SYNCPropertyMapperRelationshipType)relationshipType;

- (NSAttributeDescription *)attributeDescriptionForRemoteKey:(NSString *)remoteKey;

- (NSAttributeDescription *)attributeDescriptionForRemoteKey:(NSString *)remoteKey
                                         usingInflectionType:(SYNCPropertyMapperInflectionType)inflectionType;

- (NSArray *)attributeDescriptionsForRemoteKeyPath:(NSString *)key;

- (id)valueForAttributeDescription:(id)attributeDescription
                  usingRemoteValue:(id)removeValue;

- (NSString *)remoteKeyForAttributeDescription:(NSAttributeDescription *)attributeDescription;

- (NSString *)remoteKeyForAttributeDescription:(NSAttributeDescription *)attributeDescription
                                inflectionType:(SYNCPropertyMapperInflectionType)inflectionType;

- (NSString *)remoteKeyForAttributeDescription:(NSAttributeDescription *)attributeDescription
                         usingRelationshipType:(SYNCPropertyMapperRelationshipType)relationshipType;

- (NSString *)remoteKeyForAttributeDescription:(NSAttributeDescription *)attributeDescription
                         usingRelationshipType:(SYNCPropertyMapperRelationshipType)relationshipType
                                inflectionType:(SYNCPropertyMapperInflectionType)inflectionType;

+ (NSArray *)reservedAttributes;

- (NSString *)prefixedAttribute:(NSString *)attribute
            usingInflectionType:(SYNCPropertyMapperInflectionType)inflectionType;

@end
