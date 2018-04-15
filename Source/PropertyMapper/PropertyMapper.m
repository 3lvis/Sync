#import "PropertyMapper.h"

#import "Inflections.h"
#import "NSManagedObject+PropertyMapperHelpers.h"
#import "NSDate+PropertyMapper.h"
#import "NSPropertyDescription+Sync.h"

static NSString * const PropertyMapperNestedAttributesKey = @"attributes";

@implementation NSManagedObject (PropertyMapper)

#pragma mark - Public methods

- (void)fillWithDictionary:(NSDictionary<NSString *, id> *)dictionary {
    [self hyp_fillWithDictionary:dictionary];
}

- (void)hyp_fillWithDictionary:(NSDictionary<NSString *, id> *)dictionary {
    for (__strong NSString *key in dictionary) {
        id value = [dictionary objectForKey:key];

        NSAttributeDescription *attributeDescription = [self attributeDescriptionForRemoteKey:key];
        if (attributeDescription) {
            BOOL valueExists = (value && ![value isKindOfClass:[NSNull class]]);
            if (valueExists && [value isKindOfClass:[NSDictionary class]] && attributeDescription.attributeType != NSBinaryDataAttributeType) {
                NSString *remoteKey = [self remoteKeyForAttributeDescription:attributeDescription
                                                              inflectionType:SyncPropertyMapperInflectionTypeSnakeCase];
                BOOL hasCustomKeyPath = remoteKey && [remoteKey rangeOfString:@"."].location != NSNotFound;
                if (hasCustomKeyPath) {
                    NSArray *keyPathAttributeDescriptions = [self attributeDescriptionsForRemoteKeyPath:remoteKey];
                    for (NSAttributeDescription *keyPathAttributeDescription in keyPathAttributeDescriptions) {
                        NSString *remoteKey = [self remoteKeyForAttributeDescription:keyPathAttributeDescription
                                                                      inflectionType:SyncPropertyMapperInflectionTypeSnakeCase];
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
    return [self hyp_dictionaryUsingInflectionType:SyncPropertyMapperInflectionTypeSnakeCase];
}

- (NSDictionary<NSString *, id> *)hyp_dictionaryUsingInflectionType:(SyncPropertyMapperInflectionType)inflectionType {
    return [self hyp_dictionaryWithDateFormatter:[self defaultDateFormatter]
                                          parent:nil
                             usingInflectionType:inflectionType
                             andRelationshipType:SyncPropertyMapperRelationshipTypeNested];
}

- (NSDictionary<NSString *, id> *)hyp_dictionaryUsinginflectionType:(SyncPropertyMapperInflectionType)inflectionType
                                                andRelationshipType:(SyncPropertyMapperRelationshipType)relationshipType {
    return [self hyp_dictionaryWithDateFormatter:[self defaultDateFormatter]
                                          parent:nil
                             usingInflectionType:inflectionType
                             andRelationshipType:relationshipType];
}

- (NSDictionary<NSString *, id> *)hyp_dictionaryUsingRelationshipType:(SyncPropertyMapperRelationshipType)relationshipType {
    return [self hyp_dictionaryWithDateFormatter:[self defaultDateFormatter]
                           usingRelationshipType:relationshipType];
}

- (NSDictionary<NSString *, id> *)hyp_dictionaryUsingInflectionType:(SyncPropertyMapperInflectionType)inflectionType
                                                andRelationshipType:(SyncPropertyMapperRelationshipType)relationshipType {
    return [self hyp_dictionaryWithDateFormatter:[self defaultDateFormatter]
                                          parent:nil
                             usingInflectionType:inflectionType
                             andRelationshipType:relationshipType];
}

- (NSDictionary<NSString *, id> *)hyp_dictionaryWithDateFormatter:(NSDateFormatter *)dateFormatter {
    return [self hyp_dictionaryWithDateFormatter:dateFormatter
                                          parent:nil
                           usingRelationshipType:SyncPropertyMapperRelationshipTypeNested];
}

- (NSDictionary<NSString *, id> *)hyp_dictionaryWithDateFormatter:(NSDateFormatter *)dateFormatter
                                            usingRelationshipType:(SyncPropertyMapperRelationshipType)relationshipType {
    return [self hyp_dictionaryWithDateFormatter:dateFormatter
                                          parent:nil
                           usingRelationshipType:relationshipType];
}

- (NSDictionary<NSString *, id> *)hyp_dictionaryWithDateFormatter:(NSDateFormatter *)dateFormatter
                                              usingInflectionType:(SyncPropertyMapperInflectionType)inflectionType {
    return [self hyp_dictionaryWithDateFormatter:dateFormatter
                                          parent:nil
                             usingInflectionType:inflectionType
                             andRelationshipType:SyncPropertyMapperRelationshipTypeNested];
}

- (NSDictionary<NSString *, id> *)hyp_dictionaryWithDateFormatter:(NSDateFormatter *)dateFormatter
                                              usingInflectionType:(SyncPropertyMapperInflectionType)inflectionType
                                              andRelationshipType:(SyncPropertyMapperRelationshipType)relationshipType {
    return [self hyp_dictionaryWithDateFormatter:dateFormatter
                                          parent:nil
                             usingInflectionType:inflectionType
                             andRelationshipType:relationshipType];
}

- (NSDictionary<NSString *, id> *)hyp_dictionaryWithDateFormatter:(NSDateFormatter *)dateFormatter
                                                           parent:( NSManagedObject * _Nullable )parent
                                            usingRelationshipType:(SyncPropertyMapperRelationshipType)relationshipType {
    return [self hyp_dictionaryWithDateFormatter:dateFormatter
                                          parent:parent
                             usingInflectionType:SyncPropertyMapperInflectionTypeSnakeCase
                             andRelationshipType:relationshipType];
}

- (NSDictionary<NSString *, id> *)hyp_dictionaryWithDateFormatter:(NSDateFormatter *)dateFormatter
                                                           parent:( NSManagedObject * _Nullable )parent
                                              usingInflectionType:(SyncPropertyMapperInflectionType)inflectionType
                                              andRelationshipType:(SyncPropertyMapperRelationshipType)relationshipType {
    NSMutableDictionary *managedObjectAttributes = [NSMutableDictionary new];

    for (id propertyDescription in self.entity.properties) {
        if ([propertyDescription isKindOfClass:[NSAttributeDescription class]]) {
            if ([propertyDescription shouldExportAttribute]) {
                id value = [self valueForAttributeDescription:propertyDescription
                                                dateFormatter:dateFormatter
                                             relationshipType:relationshipType];
                if (value) {
                    NSString *remoteKey = [self remoteKeyForAttributeDescription:propertyDescription
                                                           usingRelationshipType:relationshipType
                                                                  inflectionType:inflectionType];
                    
                    NSMutableDictionary *currentObj = managedObjectAttributes;
                    NSArray *split = [remoteKey componentsSeparatedByString:@"."];
                    NSRange range = NSMakeRange(0, split.count - 1);
                    NSArray *components = [split subarrayWithRange:range];
                    
                    for(NSString *key in components) {
                        id currentValue = currentObj[key];
                        if(!currentValue) {
                            [currentObj setObject:[[NSMutableDictionary alloc] init] forKey: key];
                        }
                        if(currentObj[key]) {
                            currentObj = currentObj[key];
                        }
                    }
                    
                    NSString *lastKey = split.lastObject;
                    [currentObj setObject:value forKey:lastKey];
                }
            }
        } else if ([propertyDescription isKindOfClass:[NSRelationshipDescription class]] &&
                   relationshipType != SyncPropertyMapperRelationshipTypeNone) {
            NSRelationshipDescription *relationshipDescription = (NSRelationshipDescription *)propertyDescription;
            if ([relationshipDescription shouldExportAttribute]) {
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
                           usingRelationshipType:(SyncPropertyMapperRelationshipType)relationshipType
                                          parent:(NSManagedObject *)parent
                                   dateFormatter:(NSDateFormatter *)dateFormatter
                                  inflectionType:(SyncPropertyMapperInflectionType)inflectionType {

    NSMutableDictionary *attributesForToOneRelationship = [NSMutableDictionary new];
    NSDictionary *attributes = [relationship hyp_dictionaryWithDateFormatter:dateFormatter
                                                                      parent:parent
                                                         usingInflectionType:inflectionType
                                                         andRelationshipType:relationshipType];
    if (attributes.count > 0) {
        NSString *key;
        switch (inflectionType) {
            case SyncPropertyMapperInflectionTypeSnakeCase:
                key = [relationshipName hyp_snakeCase];
                break;
            case SyncPropertyMapperInflectionTypeCamelCase:
                key = relationshipName;
                break;
        }
        if (relationshipType == SyncPropertyMapperRelationshipTypeNested) {
            switch (inflectionType) {
                case SyncPropertyMapperInflectionTypeSnakeCase:
                    key = [NSString stringWithFormat:@"%@_%@", key, PropertyMapperNestedAttributesKey];
                    break;
                case SyncPropertyMapperInflectionTypeCamelCase:
                    key = [NSString stringWithFormat:@"%@%@", key, [PropertyMapperNestedAttributesKey capitalizedString]];
                    break;
            }
        }

        [attributesForToOneRelationship setValue:attributes forKey:key];
    }

    return attributesForToOneRelationship;
}

- (NSDictionary *)attributesForToManyRelationship:(NSSet *)relationships
                                 relationshipName:(NSString *)relationshipName
                            usingRelationshipType:(SyncPropertyMapperRelationshipType)relationshipType
                                           parent:(NSManagedObject *)parent
                                    dateFormatter:(NSDateFormatter *)dateFormatter
                                   inflectionType:(SyncPropertyMapperInflectionType)inflectionType {

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
            if (relationshipType == SyncPropertyMapperRelationshipTypeArray) {
                [relationsArray addObject:attributes];
            } else if (relationshipType == SyncPropertyMapperRelationshipTypeNested) {
                NSString *relationIndexString = [NSString stringWithFormat:@"%lu", (unsigned long)relationIndex];
                relationsDictionary[relationIndexString] = attributes;
                relationIndex++;
            }
        }
    }

    NSString *key;
    switch (inflectionType) {
        case SyncPropertyMapperInflectionTypeSnakeCase: {
            key = [relationshipName hyp_snakeCase];
        } break;
        case SyncPropertyMapperInflectionTypeCamelCase: {
            key = [relationshipName hyp_camelCase];
        } break;
    }
    if (relationshipType == SyncPropertyMapperRelationshipTypeArray) {
        [attributesForToManyRelationship setValue:relationsArray forKey:key];
    } else if (relationshipType == SyncPropertyMapperRelationshipTypeNested) {
        NSString *nestedAttributesPrefix = [NSString stringWithFormat:@"%@_%@", key, PropertyMapperNestedAttributesKey];
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
