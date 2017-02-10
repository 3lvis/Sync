@import CoreData;
@import Foundation;

#import "NSDate+SYNCPropertyMapper.h"
#import "NSEntityDescription+SYNCPrimaryKey.h"
#import "NSString+SYNCInflections.h"

FOUNDATION_EXPORT double SYNCPropertyMapperVersionNumber;
FOUNDATION_EXPORT const unsigned char SYNCPropertyMapperVersionString[];

NS_ASSUME_NONNULL_BEGIN

/**
 The relationship type used to export the NSManagedObject as JSON.

 - SYNCPropertyMapperRelationshipTypeNone:   Skip all relationships.
 - SYNCPropertyMapperRelationshipTypeArray:  Normal JSON representation of relationships.
 - SYNCPropertyMapperRelationshipTypeNested: Uses Ruby on Rails's accepts_nested_attributes_for notation to represent relationships.
 */
typedef NS_ENUM(NSInteger, SYNCPropertyMapperRelationshipType) {
    SYNCPropertyMapperRelationshipTypeNone = 0,
    SYNCPropertyMapperRelationshipTypeArray,
    SYNCPropertyMapperRelationshipTypeNested
};

/**
 The relationship type used to export the NSManagedObject as JSON.

 - SYNCPropertyMapperRelationshipTypeNone:   Skip all relationships.
 - SYNCPropertyMapperRelationshipTypeArray:  Normal JSON representation of relationships.
 - SYNCPropertyMapperRelationshipTypeNested: Uses Ruby on Rails's accepts_nested_attributes_for notation to represent relationships.
 */
typedef NS_ENUM(NSInteger, SYNCPropertyMapperInflectionType) {
    SYNCPropertyMapperInflectionTypeSnakeCase = 0,
    SYNCPropertyMapperInflectionTypeCamelCase
};

/**
 Collection of helper methods to facilitate mapping JSON to NSManagedObject.
 */
@interface NSManagedObject (SYNCPropertyMapper)

/**
 Fills the @c NSManagedObject with the contents of the dictionary using a convention-over-configuration paradigm mapping the Core Data attributes to their conterparts in JSON using snake_case.

 @param dictionary The JSON dictionary to be used to fill the values of your @c NSManagedObject.
 */
- (void)hyp_fillWithDictionary:(NSDictionary<NSString *, id> *)dictionary;

/**
 Creates a @c NSDictionary of values based on the @c NSManagedObject subclass that can be serialized by @c NSJSONSerialization. Includes relationships to other models using Ruby on Rail's nested attributes model.
 @c NSDate objects will be stringified to the ISO-8601 standard.

 @return The JSON representation of the @c NSManagedObject in the form of a @c NSDictionary.
 */
- (NSDictionary<NSString *, id> *)hyp_dictionary;

/**
 Creates a @c NSDictionary of values based on the @c NSManagedObject subclass that can be serialized by @c NSJSONSerialization. Includes relationships to other models using Ruby on Rail's nested attributes model.
 @c NSDate objects will be stringified to the ISO-8601 standard.

 @param inflectionType The type used to export the dictionary, can be camelCase or snakeCase.

 @return The JSON representation of the @c NSManagedObject in the form of a @c NSDictionary.
 */
- (NSDictionary<NSString *, id> *)hyp_dictionaryUsingInflectionType:(SYNCPropertyMapperInflectionType)inflectionType;

/**
 Creates a @c NSDictionary of values based on the @c NSManagedObject subclass that can be serialized by @c NSJSONSerialization. Could include relationships to other models.
 @c NSDate objects will be stringified to the ISO-8601 standard.

 @param relationshipType It indicates wheter the result dictionary should include no relationships, nested attributes or normal attributes.

 @return The JSON representation of the @c NSManagedObject in the form of a @c NSDictionary.
 */
- (NSDictionary<NSString *, id> *)hyp_dictionaryUsingRelationshipType:(SYNCPropertyMapperRelationshipType)relationshipType;


/**
 Creates a @c NSDictionary of values based on the @c NSManagedObject subclass that can be serialized by @c NSJSONSerialization. Could include relationships to other models.
 @c NSDate objects will be stringified to the ISO-8601 standard.

 @param inflectionType The type used to export the dictionary, can be camelCase or snakeCase.
 @param relationshipType It indicates wheter the result dictionary should include no relationships, nested attributes or normal attributes.
 @return The JSON representation of the @c NSManagedObject in the form of a @c NSDictionary.
 */
- (NSDictionary<NSString *, id> *)hyp_dictionaryUsingInflectionType:(SYNCPropertyMapperInflectionType)inflectionType
                                                andRelationshipType:(SYNCPropertyMapperRelationshipType)relationshipType;

/**
 Creates a @c NSDictionary of values based on the @c NSManagedObject subclass that can be serialized by @c NSJSONSerialization. Includes relationships to other models using Ruby on Rail's nested attributes model.

 @param dateFormatter A custom date formatter that turns @c NSDate objects into NSString objects. Do not pass @c nil, instead use the @c hyp_dictionary method.

 @return The JSON representation of the @c NSManagedObject in the form of a @c NSDictionary.
 */
- (NSDictionary<NSString *, id> *)hyp_dictionaryWithDateFormatter:(NSDateFormatter *)dateFormatter;

/**
 Creates a @c NSDictionary of values based on the @c NSManagedObject subclass that can be serialized by @c NSJSONSerialization. Could include relationships to other models using Ruby on Rail's nested attributes model.

 @param dateFormatter    A custom date formatter that turns @c NSDate objects into @c NSString objects. Do not pass nil, instead use the 'hyp_dictionary' method.
 @param relationshipType It indicates wheter the result dictionary should include no relationships, nested attributes or normal attributes.

 @return The JSON representation of the @c NSManagedObject in the form of a @c NSDictionary.
 */
- (NSDictionary<NSString *, id> *)hyp_dictionaryWithDateFormatter:(NSDateFormatter *)dateFormatter
                                            usingRelationshipType:(SYNCPropertyMapperRelationshipType)relationshipType;

/**
 Creates a @c NSDictionary of values based on the @c NSManagedObject subclass that can be serialized by @c NSJSONSerialization. Could include relationships to other models using Ruby on Rail's nested attributes model.

 @param dateFormatter    A custom date formatter that turns @c NSDate objects into @c NSString objects. Do not pass nil, instead use the @c hyp_dictionary method.
 @param parent           The parent of the managed object.
 @param relationshipType It indicates wheter the result dictionary should include no relationships, nested attributes or normal attributes.

 @return The JSON representation of the @c NSManagedObject in the form of a @c NSDictionary.
 */
- (NSDictionary<NSString *, id> *)hyp_dictionaryWithDateFormatter:(NSDateFormatter *)dateFormatter
                                                           parent:( NSManagedObject * _Nullable)parent
                                            usingRelationshipType:(SYNCPropertyMapperRelationshipType)relationshipType;

@end

NS_ASSUME_NONNULL_END
