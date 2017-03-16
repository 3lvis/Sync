#import "NSManagedObject+SYNCPropertyMapperHelpers.h"

#import "SYNCPropertyMapper.h"
#import "NSString+SYNCInflections.h"
#import "NSEntityDescription+SYNCPrimaryKey.h"
#import "NSDate+SYNCPropertyMapper.h"

@implementation NSManagedObject (SYNCPropertyMapperHelpers)

- (id)valueForAttributeDescription:(NSAttributeDescription *)attributeDescription
                     dateFormatter:(NSDateFormatter *)dateFormatter
                  relationshipType:(SYNCPropertyMapperRelationshipType)relationshipType {
    id value;
    if (attributeDescription.attributeType != NSTransformableAttributeType) {
        value = [self valueForKey:attributeDescription.name];
        BOOL nilOrNullValue = (!value ||
                               [value isKindOfClass:[NSNull class]]);
        NSString *customTransformerName = attributeDescription.userInfo[SYNCPropertyMapperCustomValueTransformerKey];
        if (nilOrNullValue) {
            value = [NSNull null];
        } else if ([value isKindOfClass:[NSDate class]]) {
            value = [dateFormatter stringFromDate:value];
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
    return [self attributeDescriptionForRemoteKey:remoteKey usingInflectionType:SYNCPropertyMapperInflectionTypeSnakeCase];
}

- (NSAttributeDescription *)attributeDescriptionForRemoteKey:(NSString *)remoteKey
                                         usingInflectionType:(SYNCPropertyMapperInflectionType)inflectionType {
    __block NSAttributeDescription *foundAttributeDescription;

    [self.entity.properties enumerateObjectsUsingBlock:^(id propertyDescription, NSUInteger idx, BOOL *stop) {
        if ([propertyDescription isKindOfClass:[NSAttributeDescription class]]) {
            NSAttributeDescription *attributeDescription = (NSAttributeDescription *)propertyDescription;

            NSDictionary *userInfo = [self.entity.propertiesByName[attributeDescription.name] userInfo];
            NSString *customRemoteKey = userInfo[SYNCPropertyMapperCustomRemoteKey];
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

                if ([remoteKey isEqualToString:SYNCDefaultRemotePrimaryKey] &&
                    ([attributeDescription.name isEqualToString:SYNCDefaultLocalPrimaryKey] || [attributeDescription.name isEqualToString:SYNCDefaultLocalCompatiblePrimaryKey])) {
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
            
            NSDictionary *userInfo = [self.entity.propertiesByName[attributeDescription.name] userInfo];
            NSString *customRemoteKeyPath = userInfo[SYNCPropertyMapperCustomRemoteKey];
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
    return [self remoteKeyForAttributeDescription:attributeDescription usingRelationshipType:SYNCPropertyMapperRelationshipTypeNested inflectionType:SYNCPropertyMapperInflectionTypeSnakeCase];
}

- (NSString *)remoteKeyForAttributeDescription:(NSAttributeDescription *)attributeDescription
                                inflectionType:(SYNCPropertyMapperInflectionType)inflectionType {
    return [self remoteKeyForAttributeDescription:attributeDescription usingRelationshipType:SYNCPropertyMapperRelationshipTypeNested inflectionType:inflectionType];
}

- (NSString *)remoteKeyForAttributeDescription:(NSAttributeDescription *)attributeDescription
                         usingRelationshipType:(SYNCPropertyMapperRelationshipType)relationshipType {
    return [self remoteKeyForAttributeDescription:attributeDescription usingRelationshipType:relationshipType inflectionType:SYNCPropertyMapperInflectionTypeSnakeCase];
}

- (NSString *)remoteKeyForAttributeDescription:(NSAttributeDescription *)attributeDescription
                         usingRelationshipType:(SYNCPropertyMapperRelationshipType)relationshipType
                                inflectionType:(SYNCPropertyMapperInflectionType)inflectionType {
    NSDictionary *userInfo = attributeDescription.userInfo;
    NSString *localKey = attributeDescription.name;
    NSString *remoteKey;

    NSString *customRemoteKey = userInfo[SYNCPropertyMapperCustomRemoteKey];
    if (customRemoteKey) {
        remoteKey = customRemoteKey;
    } else if ([localKey isEqualToString:SYNCDefaultLocalPrimaryKey] || [localKey isEqualToString:SYNCDefaultLocalCompatiblePrimaryKey]) {
        remoteKey = SYNCDefaultRemotePrimaryKey;
    } else if ([localKey isEqualToString:SYNCPropertyMapperDestroyKey] &&
               relationshipType == SYNCPropertyMapperRelationshipTypeNested) {
        remoteKey = [NSString stringWithFormat:@"_%@", SYNCPropertyMapperDestroyKey];
    } else {
        switch (inflectionType) {
            case SYNCPropertyMapperInflectionTypeSnakeCase:
                remoteKey = [localKey hyp_snakeCase];
                break;
            case SYNCPropertyMapperInflectionTypeCamelCase:
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
        if (inflectionType == SYNCPropertyMapperInflectionTypeCamelCase) {
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

    NSString *customTransformerName = attributeDescription.userInfo[SYNCPropertyMapperCustomValueTransformerKey];
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

- (NSString *)remotePrefixUsingInflectionType:(SYNCPropertyMapperInflectionType)inflectionType {
    switch (inflectionType) {
        case SYNCPropertyMapperInflectionTypeSnakeCase:
            return [NSString stringWithFormat:@"%@_", [self.entity.name hyp_snakeCase]];
            break;
        case SYNCPropertyMapperInflectionTypeCamelCase:
            return [self.entity.name hyp_camelCase];
            break;
    }
}

- (NSString *)prefixedAttribute:(NSString *)attribute usingInflectionType:(SYNCPropertyMapperInflectionType)inflectionType {
    NSString *remotePrefix = [self remotePrefixUsingInflectionType:inflectionType];

    switch (inflectionType) {
        case SYNCPropertyMapperInflectionTypeSnakeCase: {
            return [NSString stringWithFormat:@"%@%@", remotePrefix, attribute];
        } break;
        case SYNCPropertyMapperInflectionTypeCamelCase: {
            return [NSString stringWithFormat:@"%@%@", remotePrefix, [attribute capitalizedString]];
        } break;
    }
}

- (NSArray *)reservedKeysUsingInflectionType:(SYNCPropertyMapperInflectionType)inflectionType {
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
