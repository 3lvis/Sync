#import "NSString+HYPNetworking.h"

@interface NSString (PrivateInflections)

- (BOOL)hyp_containsWord:(NSString *)word;
- (NSString *)hyp_lowerCaseFirstLetter;
- (NSString *)hyp_replaceIdentifierWithString:(NSString *)replacementString;

@end

@implementation NSString (HYPNetworking)

#pragma mark - Private methods

- (NSString *)hyp_remoteString
{
    NSString *processedString = [self hyp_replaceIdentifierWithString:@"_"];

    return [processedString hyp_lowerCaseFirstLetter];
}

- (NSString *)hyp_localString
{
    NSString *processedString = self;

    processedString = [processedString hyp_replaceIdentifierWithString:@""];

    BOOL remoteStringIsAnAcronym = ([[NSString acronyms] containsObject:[processedString lowercaseString]]);

    return (remoteStringIsAnAcronym) ? [processedString lowercaseString] : [processedString hyp_lowerCaseFirstLetter];
}

- (BOOL)hyp_containsWord:(NSString *)word
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

- (NSString *)hyp_lowerCaseFirstLetter
{
    NSMutableString *mutableString = [[NSMutableString alloc] initWithString:self];
    NSString *firstLetter = [[mutableString substringToIndex:1] lowercaseString];
    [mutableString replaceCharactersInRange:NSMakeRange(0,1)
                                 withString:firstLetter];

    return [mutableString copy];
}

- (NSString *)hyp_replaceIdentifierWithString:(NSString *)replacementString
{
    NSScanner *scanner = [NSScanner scannerWithString:self];
    scanner.caseSensitive = YES;

    NSCharacterSet *identifierSet = [NSCharacterSet characterSetWithCharactersInString:@"_- "];

    NSCharacterSet *alphanumericSet = [NSCharacterSet alphanumericCharacterSet];
    NSCharacterSet *uppercaseSet = [NSCharacterSet uppercaseLetterCharacterSet];
    NSCharacterSet *lowercaseSet = [NSCharacterSet lowercaseLetterCharacterSet];

    NSString *buffer = nil;
    NSMutableString *output = [NSMutableString string];

    while (!scanner.isAtEnd) {
        BOOL isExcludedCharacter = [scanner scanCharactersFromSet:identifierSet intoString:&buffer];
        if (isExcludedCharacter) continue;

        if ([replacementString length] > 0) {
            BOOL isUppercaseCharacter = [scanner scanCharactersFromSet:uppercaseSet intoString:&buffer];
            if (isUppercaseCharacter) {
                [output appendString:replacementString];
                [output appendString:[buffer lowercaseString]];
            }

            BOOL isLowercaseCharacter = [scanner scanCharactersFromSet:lowercaseSet intoString:&buffer];
            if (isLowercaseCharacter) {
                [output appendString:[buffer lowercaseString]];
            }

        } else if ([scanner scanCharactersFromSet:alphanumericSet intoString:&buffer]) {
            if ([[NSString acronyms] containsObject:buffer]) {
                [output appendString:[buffer uppercaseString]];
            } else {
                [output appendString:[buffer capitalizedString]];
            }
        } else {
            output = nil;
            break;
        }
    }

    return output;
}

+ (NSArray *)acronyms
{
    return @[@"id", @"pdf", @"url", @"png", @"jpg"];
}

@end
