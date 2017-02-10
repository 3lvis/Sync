#import "SYNCPropertyMapper.h"

#import "NSString+SYNCInflections.h"
#import "NSManagedObject+SYNCPropertyMapperHelpers.h"
#import "NSDate+SYNCPropertyMapper.h"

static NSString * const SYNCPropertyMapperNestedAttributesKey = @"attributes";

@implementation NSManagedObject (SYNCPropertyMapper)

#pragma mark - Public methods

- (void)hyp_fillWithDictionary:(NSDictionary<NSString *, id> *)dictionary {
    for (__strong NSString *key in dictionary) {
        id value = [dictionary objectForKey:key];

        NSAttributeDescription *attributeDescription = [self attributeDescriptionForRemoteKey:key];
        if (attributeDescription) {
            BOOL valueExists = (value && ![value isKindOfClass:[NSNull class]]);
            if (valueExists && [value isKindOfClass:[NSDictionary class]] && attributeDescription.attributeType != NSBinaryDataAttributeType) {
                NSString *remoteKey = [self remoteKeyForAttributeDescription:attributeDescription
                                                              inflectionType:SYNCPropertyMapperInflectionTypeSnakeCase];
                BOOL hasCustomKeyPath = remoteKey && [remoteKey rangeOfString:@"."].location != NSNotFound;
                if (hasCustomKeyPath) {
                    NSArray *keyPathAttributeDescriptions = [self attributeDescriptionsForRemoteKeyPath:remoteKey];
                    for (NSAttributeDescription *keyPathAttributeDescription in keyPathAttributeDescriptions) {
                        NSString *remoteKey = [self remoteKeyForAttributeDescription:keyPathAttributeDescription
                                                                      inflectionType:SYNCPropertyMapperInflectionTypeSnakeCase];
                        NSString *localKey = keyPathAttributeDescription.name;
                        [self hyp_setDictionaryValue:[dictionary valueForKeyPath:remoteKey]
                                              forKey:localKey
                                attributeDescription:keyPathAttributeDescription];
                    }
                }
            } else {
                NSString *localKey = attributeDescription.name;
                [self hyp_setDictionaryValue:value
                                      forKey:localKey
                        attributeDescription:attributeDescription];
            }
        }
    }
}

- (void)hyp_setDictionaryValue:(id)value forKey:(NSString *)key
          attributeDescription:(NSAttributeDescription *)attributeDescription {
    BOOL valueExists = (value && ![value isKindOfClass:[NSNull class]]);
    if (valueExists) {
        id processedValue = [self valueForAttributeDescription:attributeDescription
                                              usingRemoteValue:value];
        
        BOOL valueHasChanged = (![[self valueForKey:key] isEqual:processedValue]);
        if (valueHasChanged) {
            [self setValue:processedValue forKey:key];
        }
    } else if ([self valueForKey:key]) {
        [self setValue:nil forKey:key];
    }
}

- (NSDictionary<NSString *, id> *)hyp_dictionary {
    return [self hyp_dictionaryUsingInflectionType:SYNCPropertyMapperInflectionTypeSnakeCase];
}

- (NSDictionary<NSString *, id> *)hyp_dictionaryUsingInflectionType:(SYNCPropertyMapperInflectionType)inflectionType {
    return [self hyp_dictionaryWithDateFormatter:[self defaultDateFormatter]
                                          parent:nil usingInflectionType:inflectionType
                             andRelationshipType:SYNCPropertyMapperRelationshipTypeNested];
}

- (NSDictionary<NSString *, id> *)hyp_dictionaryUsinginflectionType:(SYNCPropertyMapperInflectionType)inflectionType
                                                andRelationshipType:(SYNCPropertyMapperRelationshipType)relationshipType {
    return [self hyp_dictionaryWithDateFormatter:[self defaultDateFormatter]
                                          parent:nil
                             usingInflectionType:inflectionType
                             andRelationshipType:relationshipType];
}

- (NSDictionary<NSString *, id> *)hyp_dictionaryUsingRelationshipType:(SYNCPropertyMapperRelationshipType)relationshipType {
    return [self hyp_dictionaryWithDateFormatter:[self defaultDateFormatter]
                           usingRelationshipType:relationshipType];
}

- (NSDictionary<NSString *, id> *)hyp_dictionaryUsingInflectionType:(SYNCPropertyMapperInflectionType)inflectionType
                                                andRelationshipType:(SYNCPropertyMapperRelationshipType)relationshipType {
    return [self hyp_dictionaryWithDateFormatter:[self defaultDateFormatter]
                                          parent:nil
                             usingInflectionType:inflectionType
                             andRelationshipType:relationshipType];
}

- (NSDictionary<NSString *, id> *)hyp_dictionaryWithDateFormatter:(NSDateFormatter *)dateFormatter {
    return [self hyp_dictionaryWithDateFormatter:dateFormatter
                                          parent:nil
                           usingRelationshipType:SYNCPropertyMapperRelationshipTypeNested];
}

- (NSDictionary<NSString *, id> *)hyp_dictionaryWithDateFormatter:(NSDateFormatter *)dateFormatter
                                            usingRelationshipType:(SYNCPropertyMapperRelationshipType)relationshipType {
    return [self hyp_dictionaryWithDateFormatter:dateFormatter
                                          parent:nil
                           usingRelationshipType:relationshipType];
}

- (NSDictionary<NSString *, id> *)hyp_dictionaryWithDateFormatter:(NSDateFormatter *)dateFormatter
                                                           parent:( NSManagedObject * _Nullable )parent
                                            usingRelationshipType:(SYNCPropertyMapperRelationshipType)relationshipType {
    return [self hyp_dictionaryWithDateFormatter:dateFormatter
                                          parent:parent
                             usingInflectionType:SYNCPropertyMapperInflectionTypeSnakeCase
                             andRelationshipType:relationshipType];
}

- (NSDictionary<NSString *, id> *)hyp_dictionaryWithDateFormatter:(NSDateFormatter *)dateFormatter
                                                           parent:( NSManagedObject * _Nullable )parent
                                              usingInflectionType:(SYNCPropertyMapperInflectionType)inflectionType
                                              andRelationshipType:(SYNCPropertyMapperRelationshipType)relationshipType {
    NSMutableDictionary *managedObjectAttributes = [NSMutableDictionary new];

    for (id propertyDescription in self.entity.properties) {
        if ([propertyDescription isKindOfClass:[NSAttributeDescription class]]) {
            NSDictionary *userInfo = [propertyDescription userInfo];
            NSString *nonExportableKey = userInfo[SYNCPropertyMapperNonExportableKey];
            BOOL shouldExportAttribute = (nonExportableKey == nil);
            if (shouldExportAttribute) {
                id value = [self valueForAttributeDescription:propertyDescription
                                                dateFormatter:dateFormatter
                                             relationshipType:relationshipType];
                if (value) {
                    NSString *remoteKey = [self remoteKeyForAttributeDescription:propertyDescription
                                                           usingRelationshipType:relationshipType
                                                                  inflectionType:inflectionType];
                    managedObjectAttributes[remoteKey] = value;
                }
            }
        } else if ([propertyDescription isKindOfClass:[NSRelationshipDescription class]] &&
                   relationshipType != SYNCPropertyMapperRelationshipTypeNone) {
            NSRelationshipDescription *relationshipDescription = (NSRelationshipDescription *)propertyDescription;
            NSDictionary *userInfo = relationshipDescription.userInfo;
            NSString *nonExportableKey = userInfo[SYNCPropertyMapperNonExportableKey];
            if (nonExportableKey == nil) {
                BOOL isValidRelationship = !(parent && [parent.entity isEqual:relationshipDescription.destinationEntity] && !relationshipDescription.isToMany);
                if (isValidRelationship) {
                    NSString *relationshipName = [relationshipDescription name];
                    id relationships = [self valueForKey:relationshipName];
                    if (relationships) {
                        BOOL isToOneRelationship = (![relationships isKindOfClass:[NSSet class]] && ![relationships isKindOfClass:[NSOrderedSet class]]);
                        if (isToOneRelationship) {
                            NSDictionary *attributesForToOneRelationship = [self attributesForToOneRelationship:relationships
                                                                                               relationshipName:relationshipName
                                                                                          usingRelationshipType:relationshipType
                                                                                                         parent:self
                                                                                                  dateFormatter:dateFormatter
                                                                                                 inflectionType:inflectionType];
                            [managedObjectAttributes addEntriesFromDictionary:attributesForToOneRelationship];
                        } else {
                            NSDictionary *attributesForToManyRelationship = [self attributesForToManyRelationship:relationships
                                                                                                 relationshipName:relationshipName
                                                                                            usingRelationshipType:relationshipType
                                                                                                           parent:self
                                                                                                    dateFormatter:dateFormatter
                                                                                                   inflectionType:inflectionType];
                            [managedObjectAttributes addEntriesFromDictionary:attributesForToManyRelationship];
                        }
                    }
                }
            }
        }
    }

    return [managedObjectAttributes copy];
}

- (NSDictionary *)attributesForToOneRelationship:(NSManagedObject *)relationship
                                relationshipName:(NSString *)relationshipName
                           usingRelationshipType:(SYNCPropertyMapperRelationshipType)relationshipType
                                          parent:(NSManagedObject *)parent
                                   dateFormatter:(NSDateFormatter *)dateFormatter
                                  inflectionType:(SYNCPropertyMapperInflectionType)inflectionType {

    NSMutableDictionary *attributesForToOneRelationship = [NSMutableDictionary new];
    NSDictionary *attributes = [relationship hyp_dictionaryWithDateFormatter:dateFormatter
                                                                      parent:parent
                                                         usingInflectionType:inflectionType
                                                         andRelationshipType:relationshipType];
    if (attributes.count > 0) {
        NSString *key;
        switch (inflectionType) {
            case SYNCPropertyMapperInflectionTypeSnakeCase:
                key = [relationshipName hyp_snakeCase];
                break;
            case SYNCPropertyMapperInflectionTypeCamelCase:
                key = relationshipName;
                break;
        }
        if (relationshipType == SYNCPropertyMapperRelationshipTypeNested) {
            switch (inflectionType) {
                case SYNCPropertyMapperInflectionTypeSnakeCase:
                    key = [NSString stringWithFormat:@"%@_%@", key, SYNCPropertyMapperNestedAttributesKey];
                    break;
                case SYNCPropertyMapperInflectionTypeCamelCase:
                    key = [NSString stringWithFormat:@"%@%@", key, [SYNCPropertyMapperNestedAttributesKey capitalizedString]];
                    break;
            }
        }

        [attributesForToOneRelationship setValue:attributes forKey:key];
    }

    return attributesForToOneRelationship;
}

- (NSDictionary *)attributesForToManyRelationship:(NSSet *)relationships
                                 relationshipName:(NSString *)relationshipName
                            usingRelationshipType:(SYNCPropertyMapperRelationshipType)relationshipType
                                           parent:(NSManagedObject *)parent
                                    dateFormatter:(NSDateFormatter *)dateFormatter
                                   inflectionType:(SYNCPropertyMapperInflectionType)inflectionType {

    NSMutableDictionary *attributesForToManyRelationship = [NSMutableDictionary new];
    NSUInteger relationIndex = 0;
    NSMutableDictionary *relationsDictionary = [NSMutableDictionary new];
    NSMutableArray *relationsArray = [NSMutableArray new];
    for (NSManagedObject *relationship in relationships) {
        NSDictionary *attributes = [relationship hyp_dictionaryWithDateFormatter:dateFormatter
                                                                          parent:parent
                                                             usingInflectionType:inflectionType
                                                             andRelationshipType:relationshipType];
        if (attributes.count > 0) {
            if (relationshipType == SYNCPropertyMapperRelationshipTypeArray) {
                [relationsArray addObject:attributes];
            } else if (relationshipType == SYNCPropertyMapperRelationshipTypeNested) {
                NSString *relationIndexString = [NSString stringWithFormat:@"%lu", (unsigned long)relationIndex];
                relationsDictionary[relationIndexString] = attributes;
                relationIndex++;
            }
        }
    }

    NSString *key;
    switch (inflectionType) {
        case SYNCPropertyMapperInflectionTypeSnakeCase: {
            key = [relationshipName hyp_snakeCase];
        } break;
        case SYNCPropertyMapperInflectionTypeCamelCase: {
            key = [relationshipName hyp_camelCase];
        } break;
    }
    if (relationshipType == SYNCPropertyMapperRelationshipTypeArray) {
        [attributesForToManyRelationship setValue:relationsArray forKey:key];
    } else if (relationshipType == SYNCPropertyMapperRelationshipTypeNested) {
        NSString *nestedAttributesPrefix = [NSString stringWithFormat:@"%@_%@", key, SYNCPropertyMapperNestedAttributesKey];
        [attributesForToManyRelationship setValue:relationsDictionary forKey:nestedAttributesPrefix];
    }

    return attributesForToManyRelationship;
}

#pragma mark - Private

- (NSDateFormatter *)defaultDateFormatter {
    static NSDateFormatter *_dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [NSDateFormatter new];
        _dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        _dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";
    });
    
    return _dateFormatter;
}

@end
