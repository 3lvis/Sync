//
//  NSManagedObject+HYPPropertyMapper.m
//
//  Created by Christoffer Winterkvist on 7/2/14.
//  Copyright (c) 2014 Hyper. All rights reserved.
//

#import "NSManagedObject+HYPPropertyMapper.h"

@implementation NSString (PrivateInflections)

#pragma mark - Private methods

- (NSString *)remoteString
{
    NSString *processedString = [self replacementIdentifier:@"_"];

    if ([processedString containsWord:@"date"]) {
        NSString *replacedString = [processedString stringByReplacingOccurrencesOfString:@"_date"
                                                                              withString:@"_at"];
        if ([[NSString dateAttributes] containsObject:replacedString]) {
            processedString = replacedString;
        }
    }

    return [processedString lowerCaseFirstLetter];
}

- (NSString *)localString
{
    NSString *processedString = self;

    if ([self containsWord:@"at"]) {
        processedString = [self stringByReplacingOccurrencesOfString:@"_at"
                                                          withString:@"_date"];
    }

    processedString = [processedString replacementIdentifier:@""];

    BOOL remoteStringIsAnAcronym = ([[NSString acronyms] containsObject:[processedString lowercaseString]]);

    return (remoteStringIsAnAcronym) ? [processedString lowercaseString] : [processedString lowerCaseFirstLetter];
}

- (BOOL)containsWord:(NSString *)word
{
    BOOL found = NO;

    NSArray *components = [self componentsSeparatedByString:@"_"];

    for (NSString *component in components) {
        if ([component isEqualToString:word]) {
            found = YES;
            break;
        }
    }

    return found;
}

- (NSString *)lowerCaseFirstLetter
{
    NSMutableString *mutableString = [[NSMutableString alloc] initWithString:self];
    NSString *firstLetter = [[mutableString substringToIndex:1] lowercaseString];
    [mutableString replaceCharactersInRange:NSMakeRange(0,1)
                                 withString:firstLetter];

    return [mutableString copy];
}

- (NSString *)replacementIdentifier:(NSString *)replacementString
{
    NSScanner *scanner = [NSScanner scannerWithString:self];
    scanner.caseSensitive = YES;

    NSCharacterSet *identifierSet   = [NSCharacterSet characterSetWithCharactersInString:@"_- "];
    NSCharacterSet *alphanumericSet = [NSCharacterSet alphanumericCharacterSet];
    NSCharacterSet *uppercaseSet    = [NSCharacterSet uppercaseLetterCharacterSet];
    NSCharacterSet *lowercaseSet    = [NSCharacterSet lowercaseLetterCharacterSet];

    NSString *buffer;
    NSMutableString *output = [NSMutableString string];

    while (!scanner.isAtEnd) {
        if ([scanner scanCharactersFromSet:identifierSet intoString:&buffer]) {
            continue;
        }

        if (replacementString.length > 0) {
            if ([scanner scanCharactersFromSet:uppercaseSet intoString:&buffer]) {

                if (output.length > 0) {
                    [output appendString:replacementString];
                }

                [output appendString:[buffer lowercaseString]];
            }
            if ([scanner scanCharactersFromSet:lowercaseSet intoString:&buffer]) {
                [output appendString:[buffer lowercaseString]];
            }
        } else {
            if ([scanner scanCharactersFromSet:alphanumericSet intoString:&buffer]) {
                if ([[NSString acronyms] containsObject:buffer]) {
                    [output appendString:[buffer uppercaseString]];
                } else {
                    [output appendString:[buffer capitalizedString]];
                }
            }
        }
    }

    return [output copy];
}

+ (NSArray *)acronyms
{
    return @[@"id", @"pdf", @"url", @"png", @"jpg"];
}

+ (NSArray *)dateAttributes
{
    return @[@"created_at", @"updated_at"];
}

@end

@implementation NSDate (ISO8601)

+ (NSDate *)__dateFromISO8601String:(NSString *)iso8601
{
    if (!iso8601 || [iso8601 isEqual:[NSNull null]]) return nil;

    if ([iso8601 isKindOfClass:[NSNumber class]]) {
        return [NSDate dateWithTimeIntervalSince1970:[(NSNumber *)iso8601 doubleValue]];
    } else if ([iso8601 isKindOfClass:[NSString class]]) {

        if (!iso8601) return nil;

        const char *str = [iso8601 cStringUsingEncoding:NSUTF8StringEncoding];
        char newStr[25];

        struct tm tm;
        size_t len = strlen(str);

        if (len == 0) return nil;

        if (len == 20 && str[len - 1] == 'Z') {        // UTC
            strncpy(newStr, str, len - 1);
            strncpy(newStr + len - 1, "+0000", 5);
        } else if (len == 24 && str[len - 1] == 'Z') { // Milliseconds parsing
            strncpy(newStr, str, len - 1);
            strncpy(newStr, str, len - 5);
            strncpy(newStr + len - 5, "+0000", 5);
        } else if (len == 25 && str[22] == ':') {      // Timezone
            strncpy(newStr, str, 22);
            strncpy(newStr + 22, str + 23, 2);
        } else {                                       // Poorly formatted timezone
            strncpy(newStr, str, len > 24 ? 24 : len);
        }

        // Add null terminator
        newStr[sizeof(newStr) - 1] = 0;

        if (strptime(newStr, "%FT%T%z", &tm) == NULL) return nil;

        time_t t;
        t = mktime(&tm);

        NSDate *returnedDate = [NSDate dateWithTimeIntervalSince1970:t];
        return returnedDate;
    }

    NSAssert1(NO, @"Failed to parse date: %@", iso8601);
    return nil;
}

@end

@implementation NSManagedObject (HYPPropertyMapper)

- (void)hyp_fillWithDictionary:(NSDictionary *)dictionary
{
    for (__strong NSString *remoteKey in dictionary) {

        id value = [dictionary objectForKey:remoteKey];

        BOOL isReservedKey = ([[NSManagedObject reservedAttributes] containsObject:remoteKey]);
        if (isReservedKey) {
            remoteKey = [self prefixedAttribute:remoteKey];
        }

        id propertyDescription = [self propertyDescriptionForKey:remoteKey];
        if (!propertyDescription) continue;

        NSString *localKey = [propertyDescription name];

        if (value && ![value isKindOfClass:[NSNull class]]) {

            id procesedValue = [self valueForPropertyDescription:propertyDescription
                                                usingRemoteValue:value];


            if (![[self valueForKey:localKey] isEqual:procesedValue]) {
                [self setValue:procesedValue forKey:localKey];
            }

        } else {
            if ([self valueForKey:localKey]) {
                [self setValue:nil forKey:localKey];
            }
        }
    }
}

- (id)propertyDescriptionForKey:(NSString *)key
{
    for (id propertyDescription in [self.entity properties]) {

        if (![propertyDescription isKindOfClass:[NSAttributeDescription class]]) continue;

        if ([[propertyDescription name] isEqualToString:[key localString]]) {
            return propertyDescription;
        }
    }

    return nil;
}

- (id)valueForPropertyDescription:(id)propertyDescription usingRemoteValue:(id)value
{
    NSAttributeDescription *attributeDescription = (NSAttributeDescription *)propertyDescription;
    Class attributedClass = NSClassFromString([attributeDescription attributeValueClassName]);

    if ([value isKindOfClass:attributedClass]) return value;

    BOOL stringValueAndNumberAttribute = ([value isKindOfClass:[NSString class]] &&
                                          attributedClass == [NSNumber class]);

    BOOL numberValueAndStringAttribute = ([value isKindOfClass:[NSNumber class]] &&
                                          attributedClass == [NSString class]);

    BOOL stringValueAndDateAttribute   = ([value isKindOfClass:[NSString class]] &&
                                          attributedClass == [NSDate class]);

    if (stringValueAndNumberAttribute) {
        NSNumberFormatter *formatter = [NSNumberFormatter new];
        return [formatter numberFromString:value];
    } else if (numberValueAndStringAttribute) {
        return [NSString stringWithFormat:@"%@", value];
    } else if (stringValueAndDateAttribute) {
        return [NSDate __dateFromISO8601String:value];
    }

    return nil;
}

- (NSDictionary *)hyp_dictionary
{
    NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionary];

    for (id propertyDescription in [self.entity properties]) {

        if ([propertyDescription isKindOfClass:[NSAttributeDescription class]]) {

            NSAttributeDescription *attributeDescription = (NSAttributeDescription *)propertyDescription;
            id value = [self valueForKey:[attributeDescription name]];
            NSMutableString *key = [[[propertyDescription name] remoteString] mutableCopy];

            BOOL nilOrNullValue = (!value || [value isKindOfClass:[NSNull class]]);
            if (nilOrNullValue) {
                mutableDictionary[key] = [NSNull null];
            } else {
                NSMutableString *key = [[[propertyDescription name] remoteString] mutableCopy];
                BOOL isReservedKey = ([[self reservedKeys] containsObject:key]);
                if (isReservedKey) {
                    [key replaceOccurrencesOfString:[self remotePrefix]
                                         withString:@""
                                            options:NSCaseInsensitiveSearch
                                              range:NSMakeRange(0, key.length)];
                }

                mutableDictionary[key] = value;
            }
        }
    }

    return [mutableDictionary copy];
}

- (NSString *)remotePrefix
{
    return [NSString stringWithFormat:@"%@_", [self.entity.name lowercaseString]];
}

- (NSString *)prefixedAttribute:(NSString *)attribute
{
    return [NSString stringWithFormat:@"%@%@", [self remotePrefix], attribute];
}

- (NSArray *)reservedKeys
{
    NSMutableArray *keys = [NSMutableArray array];
    NSArray *reservedAttributes = [NSManagedObject reservedAttributes];

    for (NSString *attribute in reservedAttributes) {
        [keys addObject:[self prefixedAttribute:attribute]];
    }

    return keys;
}

+ (NSArray *)reservedAttributes
{
    return @[@"id", @"type", @"description", @"signed"];
}

@end
