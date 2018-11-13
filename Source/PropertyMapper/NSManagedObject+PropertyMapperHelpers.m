#import "NSManagedObject+PropertyMapperHelpers.h"

#import "PropertyMapper.h"
#import "Inflections.h"
#import "NSEntityDescription+PrimaryKey.h"
#import "NSDate+PropertyMapper.h"
#import "NSPropertyDescription+Sync.h"

static NSString * const PropertyMapperDestroyKey = @"destroy";

@implementation NSManagedObject (PropertyMapperHelpers)

- (id)valueForAttributeDescription:(NSAttributeDescription *)attributeDescription
                     dateFormatter:(NSDateFormatter *)dateFormatter
                  relationshipType:(SyncPropertyMapperRelationshipType)relationshipType {
    id value;
    if (attributeDescription.attributeType != NSTransformableAttributeType) {
        value = [self valueForKey:attributeDescription.name];
        BOOL nilOrNullValue = (!value ||
                               [value isKindOfClass:[NSNull class]]);
        NSString *customTransformerName = [attributeDescription customTransformerName];
        if (nilOrNullValue) {
            value = [NSNull null];
        } else if ([value isKindOfClass:[NSDate class]]) {
            value = [dateFormatter stringFromDate:value];
        } else if ([value isKindOfClass:[NSUUID class]]) {
            value = [value UUIDString];
        } else if ([value isKindOfClass:[NSURL class]]) {
            value = [value absoluteString];
        } else if (customTransformerName) {
            NSValueTransformer *transformer = [NSValueTransformer valueTransformerForName:customTransformerName];
            if (transformer) {
                value = [transformer reverseTransformedValue:value];
            }
        }
    }

    return value;
}

- (NSAttributeDescription *)attributeDescriptionForRemoteKey:(NSString *)remoteKey {
    return [self attributeDescriptionForRemoteKey:remoteKey usingInflectionType:SyncPropertyMapperInflectionTypeSnakeCase];
}

- (NSAttributeDescription *)attributeDescriptionForRemoteKey:(NSString *)remoteKey
                                         usingInflectionType:(SyncPropertyMapperInflectionType)inflectionType {
    __block NSAttributeDescription *foundAttributeDescription;

    [self.entity.properties enumerateObjectsUsingBlock:^(id propertyDescription, NSUInteger idx, BOOL *stop) {
        if ([propertyDescription isKindOfClass:[NSAttributeDescription class]]) {
            NSAttributeDescription *attributeDescription = (NSAttributeDescription *)propertyDescription;

            NSString *customRemoteKey = [self.entity.propertiesByName[attributeDescription.name] customKey];

            BOOL currentAttributeHasTheSameRemoteKey = (customRemoteKey.length > 0 && [customRemoteKey isEqualToString:remoteKey]);
            if (currentAttributeHasTheSameRemoteKey) {
                foundAttributeDescription = attributeDescription;
                *stop = YES;
            }
            
            NSString *customRootRemoteKey = [[customRemoteKey componentsSeparatedByString:@"."] firstObject];
            BOOL currentAttributeHasTheSameRootRemoteKey = (customRootRemoteKey.length > 0 && [customRootRemoteKey isEqualToString:remoteKey]);
            if (currentAttributeHasTheSameRootRemoteKey) {
                foundAttributeDescription = attributeDescription;
                *stop = YES;
            }
            
            if ([attributeDescription.name isEqualToString:remoteKey]) {
                foundAttributeDescription = attributeDescription;
                *stop = YES;
            }

            NSString *localKey = [remoteKey hyp_camelCase];
            BOOL isReservedKey = ([[NSManagedObject reservedAttributes] containsObject:remoteKey]);
            if (isReservedKey) {
                NSString *prefixedRemoteKey = [self prefixedAttribute:remoteKey usingInflectionType:inflectionType];
                localKey = [prefixedRemoteKey hyp_camelCase];
            }

            if ([attributeDescription.name isEqualToString:localKey]) {
                foundAttributeDescription = attributeDescription;
                *stop = YES;
            }
        }
    }];

    if (!foundAttributeDescription) {
        [self.entity.properties enumerateObjectsUsingBlock:^(id propertyDescription, NSUInteger idx, BOOL *stop) {
            if ([propertyDescription isKindOfClass:[NSAttributeDescription class]]) {
                NSAttributeDescription *attributeDescription = (NSAttributeDescription *)propertyDescription;

                if ([remoteKey isEqualToString:SyncDefaultRemotePrimaryKey] &&
                    ([attributeDescription.name isEqualToString:SyncDefaultLocalPrimaryKey] || [attributeDescription.name isEqualToString:SyncDefaultLocalCompatiblePrimaryKey])) {
                    foundAttributeDescription = self.entity.propertiesByName[attributeDescription.name];
                }

                if (foundAttributeDescription) {
                    *stop = YES;
                }
            }
        }];
    }

    return foundAttributeDescription;
}

- (NSArray *)attributeDescriptionsForRemoteKeyPath:(NSString *)remoteKey {
    __block NSMutableArray *foundAttributeDescriptions = [NSMutableArray array];
    
    [self.entity.properties enumerateObjectsUsingBlock:^(id propertyDescription, NSUInteger idx, BOOL *stop) {
        if ([propertyDescription isKindOfClass:[NSAttributeDescription class]]) {
            NSAttributeDescription *attributeDescription = (NSAttributeDescription *)propertyDescription;
            
            NSString *customRemoteKeyPath = self.entity.propertiesByName[attributeDescription.name].customKey;
            NSString *customRootRemoteKey = [[customRemoteKeyPath componentsSeparatedByString:@"."] firstObject];
            NSString *rootRemoteKey = [[remoteKey componentsSeparatedByString:@"."] firstObject];
            BOOL currentAttributeHasTheSameRootRemoteKey = (customRootRemoteKey.length > 0 && [customRootRemoteKey isEqualToString:rootRemoteKey]);
            if (currentAttributeHasTheSameRootRemoteKey) {
                [foundAttributeDescriptions addObject:attributeDescription];
            }
        }
    }];
    
    return foundAttributeDescriptions;
}

- (NSString *)remoteKeyForAttributeDescription:(NSAttributeDescription *)attributeDescription {
    return [self remoteKeyForAttributeDescription:attributeDescription usingRelationshipType:SyncPropertyMapperRelationshipTypeNested inflectionType:SyncPropertyMapperInflectionTypeSnakeCase];
}

- (NSString *)remoteKeyForAttributeDescription:(NSAttributeDescription *)attributeDescription
                                inflectionType:(SyncPropertyMapperInflectionType)inflectionType {
    return [self remoteKeyForAttributeDescription:attributeDescription usingRelationshipType:SyncPropertyMapperRelationshipTypeNested inflectionType:inflectionType];
}

- (NSString *)remoteKeyForAttributeDescription:(NSAttributeDescription *)attributeDescription
                         usingRelationshipType:(SyncPropertyMapperRelationshipType)relationshipType {
    return [self remoteKeyForAttributeDescription:attributeDescription usingRelationshipType:relationshipType inflectionType:SyncPropertyMapperInflectionTypeSnakeCase];
}

- (NSString *)remoteKeyForAttributeDescription:(NSAttributeDescription *)attributeDescription
                         usingRelationshipType:(SyncPropertyMapperRelationshipType)relationshipType
                                inflectionType:(SyncPropertyMapperInflectionType)inflectionType {
    NSString *localKey = attributeDescription.name;
    NSString *remoteKey;

    NSString *customRemoteKey = attributeDescription.customKey;
    if (customRemoteKey) {
        remoteKey = customRemoteKey;
    } else if ([localKey isEqualToString:SyncDefaultLocalPrimaryKey] || [localKey isEqualToString:SyncDefaultLocalCompatiblePrimaryKey]) {
        remoteKey = SyncDefaultRemotePrimaryKey;
    } else if ([localKey isEqualToString:PropertyMapperDestroyKey] &&
               relationshipType == SyncPropertyMapperRelationshipTypeNested) {
        remoteKey = [NSString stringWithFormat:@"_%@", PropertyMapperDestroyKey];
    } else {
        switch (inflectionType) {
            case SyncPropertyMapperInflectionTypeSnakeCase:
                remoteKey = [localKey hyp_snakeCase];
                break;
            case SyncPropertyMapperInflectionTypeCamelCase:
                remoteKey = localKey;
                break;
        }
    }

    BOOL isReservedKey = ([[self reservedKeysUsingInflectionType:inflectionType] containsObject:remoteKey]);
    if (isReservedKey) {
        NSMutableString *prefixedKey = [remoteKey mutableCopy];
        [prefixedKey replaceOccurrencesOfString:[self remotePrefixUsingInflectionType:inflectionType]
                                     withString:@""
                                        options:NSCaseInsensitiveSearch
                                          range:NSMakeRange(0, prefixedKey.length)];
        remoteKey = [prefixedKey copy];
        if (inflectionType == SyncPropertyMapperInflectionTypeCamelCase) {
            remoteKey = [remoteKey hyp_camelCase];
        }
    }

    return remoteKey;
}

- (id)valueForAttributeDescription:(NSAttributeDescription *)attributeDescription
                  usingRemoteValue:(id)remoteValue {
    id value;

    Class attributedClass = NSClassFromString([attributeDescription attributeValueClassName]);

    if ([remoteValue isKindOfClass:attributedClass]) {
        value = remoteValue;
    }

    NSString *customTransformerName = [attributeDescription customTransformerName];
    if (customTransformerName) {
        NSValueTransformer *transformer = [NSValueTransformer valueTransformerForName:customTransformerName];
        if (transformer) {
            value = [transformer transformedValue:remoteValue];
        }
    }

    BOOL stringValueAndNumberAttribute  = ([remoteValue isKindOfClass:[NSString class]] &&
                                          attributedClass == [NSNumber class]);

    BOOL numberValueAndStringAttribute  = ([remoteValue isKindOfClass:[NSNumber class]] &&
                                          attributedClass == [NSString class]);

    BOOL stringValueAndDateAttribute    = ([remoteValue isKindOfClass:[NSString class]] &&
                                          attributedClass == [NSDate class]);

    BOOL numberValueAndDateAttribute    = ([remoteValue isKindOfClass:[NSNumber class]] &&
                                          attributedClass == [NSDate class]);
    
    BOOL stringValueAndUUIDAttribute    = ([remoteValue isKindOfClass:[NSString class]] &&
                                           attributedClass == [NSUUID class]);

    BOOL stringValueAndURIAttribute    = ([remoteValue isKindOfClass:[NSString class]] &&
                                           attributedClass == [NSURL class]);

    BOOL dataAttribute                  = (attributedClass == [NSData class]);

    BOOL numberValueAndDecimalAttribute = ([remoteValue isKindOfClass:[NSNumber class]] &&
                                           attributedClass == [NSDecimalNumber class]);

    BOOL stringValueAndDecimalAttribute = ([remoteValue isKindOfClass:[NSString class]] &&
                                           attributedClass == [NSDecimalNumber class]);

    BOOL transformableAttribute         = (!attributedClass && [attributeDescription valueTransformerName] && value == nil);

    if (stringValueAndNumberAttribute) {
        NSNumberFormatter *formatter = [NSNumberFormatter new];
        formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
        value = [formatter numberFromString:remoteValue];
    } else if (numberValueAndStringAttribute) {
        value = [NSString stringWithFormat:@"%@", remoteValue];
    } else if (stringValueAndDateAttribute) {
        value = [NSDate dateFromDateString:remoteValue];
    } else if (numberValueAndDateAttribute) {
        value = [NSDate dateFromUnixTimestampNumber:remoteValue];
    } else if (stringValueAndUUIDAttribute) {
        value = [[NSUUID alloc] initWithUUIDString:remoteValue];
    } else if (stringValueAndURIAttribute) {
        value = [[NSURL alloc] initWithString:remoteValue];
    } else if (dataAttribute) {
        value = [NSKeyedArchiver archivedDataWithRootObject:remoteValue];
    } else if (numberValueAndDecimalAttribute) {
        NSNumber *number = (NSNumber *)remoteValue;
        value = [NSDecimalNumber decimalNumberWithDecimal:[number decimalValue]];
    } else if (stringValueAndDecimalAttribute) {
        value = [NSDecimalNumber decimalNumberWithString:remoteValue];
    } else if (transformableAttribute) {
        NSValueTransformer *transformer = [NSValueTransformer valueTransformerForName:[attributeDescription valueTransformerName]];
        if (transformer) {
            id newValue = [transformer transformedValue:remoteValue];
            if (newValue) {
                value = newValue;
            }
        }
    }

    return value;
}

- (NSString *)remotePrefixUsingInflectionType:(SyncPropertyMapperInflectionType)inflectionType {
    switch (inflectionType) {
        case SyncPropertyMapperInflectionTypeSnakeCase:
            return [NSString stringWithFormat:@"%@_", [self.entity.name hyp_snakeCase]];
            break;
        case SyncPropertyMapperInflectionTypeCamelCase:
            return [self.entity.name hyp_camelCase];
            break;
    }
}

- (NSString *)prefixedAttribute:(NSString *)attribute usingInflectionType:(SyncPropertyMapperInflectionType)inflectionType {
    NSString *remotePrefix = [self remotePrefixUsingInflectionType:inflectionType];

    switch (inflectionType) {
        case SyncPropertyMapperInflectionTypeSnakeCase: {
            return [NSString stringWithFormat:@"%@%@", remotePrefix, attribute];
        } break;
        case SyncPropertyMapperInflectionTypeCamelCase: {
            return [NSString stringWithFormat:@"%@%@", remotePrefix, [attribute capitalizedString]];
        } break;
    }
}

- (NSArray *)reservedKeysUsingInflectionType:(SyncPropertyMapperInflectionType)inflectionType {
    NSMutableArray *keys = [NSMutableArray new];
    NSArray *reservedAttributes = [NSManagedObject reservedAttributes];

    for (NSString *attribute in reservedAttributes) {
        [keys addObject:[self prefixedAttribute:attribute usingInflectionType:inflectionType]];
    }

    return keys;
}

+ (NSArray *)reservedAttributes {
    return @[@"type", @"description", @"signed"];
}

@end
