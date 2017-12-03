@import CoreData;
@import Foundation;

#import "NSDate+PropertyMapper.h"
#import "NSEntityDescription+PrimaryKey.h"
#import "Inflections.h"

FOUNDATION_EXPORT double PropertyMapperVersionNumber;
FOUNDATION_EXPORT const unsigned char PropertyMapperVersionString[];

NS_ASSUME_NONNULL_BEGIN

/**
 The relationship type used to export the NSManagedObject as JSON.

 - SyncPropertyMapperRelationshipTypeNone:   Skip all relationships.
 - SyncPropertyMapperRelationshipTypeArray:  Normal JSON representation of relationships.
 - SyncPropertyMapperRelationshipTypeNested: Uses Ruby on Rails's accepts_nested_attributes_for notation to represent relationships.
 */
typedef NS_ENUM(NSInteger, SyncPropertyMapperRelationshipType) {
    SyncPropertyMapperRelationshipTypeNone = 0,
    SyncPropertyMapperRelationshipTypeArray,
    SyncPropertyMapperRelationshipTypeNested
};

/**
 The inflection type used to export the NSManagedObject as JSON.

 - SyncPropertyMapperInflectionTypeSnakeCase: Uses snake_case notation.
 - SyncPropertyMapperInflectionTypeCamelCase: Uses camelCase notation.
 */
typedef NS_ENUM(NSInteger, SyncPropertyMapperInflectionType) {
    SyncPropertyMapperInflectionTypeSnakeCase = 0,
    SyncPropertyMapperInflectionTypeCamelCase
};

/**
 Collection of helper methods to facilitate mapping JSON to NSManagedObject.
 */
@interface NSManagedObject (PropertyMapper)

/**
 Fills the @c NSManagedObject with the contents of the dictionary using a convention-over-configuration paradigm mapping the Core Data attributes to their conterparts in JSON using snake_case.

 @param dictionary The JSON dictionary to be used to fill the values of your @c NSManagedObject.
 */
- (void)hyp_fillWithDictionary:(NSDictionary<NSString *, id> *)dictionary;

/**
 Fills the @c NSManagedObject with the contents of the dictionary using a convention-over-configuration paradigm mapping the Core Data attributes to their conterparts in JSON using snake_case.

 @param dictionary The JSON dictionary to be used to fill the values of your @c NSManagedObject.
 */
- (void)fillWithDictionary:(NSDictionary<NSString *, id> *)dictionary;

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
- (NSDictionary<NSString *, id> *)hyp_dictionaryUsingInflectionType:(SyncPropertyMapperInflectionType)inflectionType;

/**
 Creates a @c NSDictionary of values based on the @c NSManagedObject subclass that can be serialized by @c NSJSONSerialization. Could include relationships to other models.
 @c NSDate objects will be stringified to the ISO-8601 standard.

 @param relationshipType It indicates wheter the result dictionary should include no relationships, nested attributes or normal attributes.

 @return The JSON representation of the @c NSManagedObject in the form of a @c NSDictionary.
 */
- (NSDictionary<NSString *, id> *)hyp_dictionaryUsingRelationshipType:(SyncPropertyMapperRelationshipType)relationshipType;


/**
 Creates a @c NSDictionary of values based on the @c NSManagedObject subclass that can be serialized by @c NSJSONSerialization. Could include relationships to other models.
 @c NSDate objects will be stringified to the ISO-8601 standard.

 @param inflectionType The type used to export the dictionary, can be camelCase or snakeCase.
 @param relationshipType It indicates wheter the result dictionary should include no relationships, nested attributes or normal attributes.
 @return The JSON representation of the @c NSManagedObject in the form of a @c NSDictionary.
 */
- (NSDictionary<NSString *, id> *)hyp_dictionaryUsingInflectionType:(SyncPropertyMapperInflectionType)inflectionType
                                                andRelationshipType:(SyncPropertyMapperRelationshipType)relationshipType;

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
                                            usingRelationshipType:(SyncPropertyMapperRelationshipType)relationshipType;

/**
 Creates a @c NSDictionary of values based on the @c NSManagedObject subclass that can be serialized by @c NSJSONSerialization. Could include relationships to other models using Ruby on Rail's nested attributes model.

 @param dateFormatter    A custom date formatter that turns @c NSDate objects into @c NSString objects. Do not pass nil, instead use the 'hyp_dictionary' method.
 @param inflectionType The type used to export the dictionary, can be camelCase or snakeCase.

 @return The JSON representation of the @c NSManagedObject in the form of a @c NSDictionary.
 */
- (NSDictionary<NSString *, id> *)hyp_dictionaryWithDateFormatter:(NSDateFormatter *)dateFormatter
                                            usingInflectionType:(SyncPropertyMapperInflectionType)inflectionType;

/**
 Creates a @c NSDictionary of values based on the @c NSManagedObject subclass that can be serialized by @c NSJSONSerialization. Could include relationships to other models using Ruby on Rail's nested attributes model.

 @param dateFormatter    A custom date formatter that turns @c NSDate objects into @c NSString objects. Do not pass nil, instead use the 'hyp_dictionary' method.
 @param inflectionType The type used to export the dictionary, can be camelCase or snakeCase.
 @param relationshipType It indicates wheter the result dictionary should include no relationships, nested attributes or normal attributes.

 @return The JSON representation of the @c NSManagedObject in the form of a @c NSDictionary.
 */
- (NSDictionary<NSString *, id> *)hyp_dictionaryWithDateFormatter:(NSDateFormatter *)dateFormatter
                                              usingInflectionType:(SyncPropertyMapperInflectionType)inflectionType
                                              andRelationshipType:(SyncPropertyMapperRelationshipType)relationshipType;

/**
 Creates a @c NSDictionary of values based on the @c NSManagedObject subclass that can be serialized by @c NSJSONSerialization. Could include relationships to other models using Ruby on Rail's nested attributes model.

 @param dateFormatter    A custom date formatter that turns @c NSDate objects into @c NSString objects. Do not pass nil, instead use the @c hyp_dictionary method.
 @param parent           The parent of the managed object.
 @param relationshipType It indicates wheter the result dictionary should include no relationships, nested attributes or normal attributes.

 @return The JSON representation of the @c NSManagedObject in the form of a @c NSDictionary.
 */
- (NSDictionary<NSString *, id> *)hyp_dictionaryWithDateFormatter:(NSDateFormatter *)dateFormatter
                                                           parent:( NSManagedObject * _Nullable)parent
                                            usingRelationshipType:(SyncPropertyMapperRelationshipType)relationshipType;

@end

NS_ASSUME_NONNULL_END
