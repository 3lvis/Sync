#import "NSDate+SYNCPropertyMapper.h"

@implementation NSDate (SYNCPropertyMapper)

+ (NSDate *)dateFromDateString:(NSString *)dateString {
    NSDate *parsedDate = nil;

    DateType dateType = [dateString dateType];
    switch (dateType) {
        case iso8601: {
            parsedDate = [self dateFromISO8601String:dateString];
        } break;
        case unixTimestamp: {
            parsedDate = [self dateFromUnixTimestampString:dateString];
        } break;
        default: break;
    }

    return parsedDate;
}

+ (NSDate *)dateFromISO8601String:(NSString *)dateString {
    if (!dateString || [dateString isEqual:[NSNull null]]) {
        return nil;
    }

    // Parse string
    else if ([dateString isKindOfClass:[NSString class]]) {
        if ([dateString length] == [DateParserDateNoTimestampFormat length]) {
            NSMutableString *mutableRemoteValue = [dateString mutableCopy];
            [mutableRemoteValue appendString:DateParserTimestamp];
            dateString = [mutableRemoteValue copy];
        }

        // Convert NSDate description to NSDate
        // Current date: 2009-10-09 00:00:00
        // Will become:  2009-10-09T00:00:00
        // Unit test L
        if ([dateString length] == [DateParserDescriptionDate length]) {
            NSString *spaceString = [dateString substringWithRange:NSMakeRange(10, 1)];
            if ([spaceString isEqualToString:@" "]) {
                dateString = [dateString stringByReplacingCharactersInRange:NSMakeRange(10, 1) withString:@"T"];
            }
        }

        const char *originalString = [dateString cStringUsingEncoding:NSUTF8StringEncoding];
        size_t originalLength = strlen(originalString);
        if (originalLength == 0) {
            return nil;
        }

        char currentString[25] = "";
        BOOL hasTimezone = NO;
        BOOL hasCentiseconds = NO;
        BOOL hasMiliseconds = NO;
        BOOL hasMicroseconds = NO;

        // ----
        // In general lines, if a Z is found, then the Z is removed since all dates operate
        // in GMT as a base, unless they have timezone, and Z is the GMT indicator.
        //
        // If +00:00 or any number after + is found, then it means that the date has a timezone.
        // This means that `hasTimezone` will have to be set to YES, and since all timezones go to
        // the end of the date, then they will be parsed at the end of the process and appended back
        // to the parsed date.
        //
        // If after the date theres `.` and a number `2014-03-30T09:13:00.XXX` the `XXX` is the milisecond
        // then `hasMiliseconds` will be set to YES. The same goes for `XX` decisecond (hasCentiseconds set to YES).
        // and microseconds `XXXXXX` (hasMicroseconds set yo YES).
        //
        // If your date format is not supported, then you'll get "Signal Sigabrt". Just ask your format to be included.
        // ----

        // Copy all the date excluding the Z.
        // Current date: 2014-03-30T09:13:00Z
        // Will become:  2014-03-30T09:13:00
        // Unit test H
        if (originalLength == 20 && originalString[originalLength - 1] == 'Z') {
            strncpy(currentString, originalString, originalLength - 1);
        }

        // Copy all the date excluding the timezone also set `hasTimezone` to YES.
        // Current date: 2014-01-01T00:00:00+00:00
        // Will become:  2014-01-01T00:00:00
        // Unit test B and C
        else if (originalLength == 25 && originalString[22] == ':') {
            strncpy(currentString, originalString, 19);
            hasTimezone = YES;
        }

        // Copy all the date excluding the miliseconds and the Z.
        // Current date: 2014-03-30T09:13:00.000Z
        // Will become:  2014-03-30T09:13:00
        // Unit test G
        else if (originalLength == 24 && originalString[originalLength - 1] == 'Z') {
            strncpy(currentString, originalString, 19);
            hasMiliseconds = YES;
        }

        // Copy all the date excluding the miliseconds and the timezone also set `hasTimezone` to YES.
        // Current date: 2015-06-23T12:40:08.000+02:00
        // Will become:  2015-06-23T12:40:08
        // Unit test A
        else if (originalLength == 29 && originalString[26] == ':') {
            strncpy(currentString, originalString, 19);
            hasTimezone = YES;
            hasMiliseconds = YES;
        }

        // Copy all the date excluding the microseconds and the timezone also set `hasTimezone` to YES.
        // Current date: 2015-08-23T09:29:30.007450+00:00
        // Will become:  2015-08-23T09:29:30
        // Unit test D
        else if (originalLength == 32 && originalString[29] == ':') {
            strncpy(currentString, originalString, 19);
            hasTimezone = YES;
            hasMicroseconds = YES;
        }

        // Copy all the date excluding the microseconds and the timezone.
        // Current date: 2015-09-10T13:47:21.116+0000
        // Will become:  2015-09-10T13:47:21
        // Unit test E
        else if (originalLength == 28 && originalString[23] == '+') {
            strncpy(currentString, originalString, 19);
        }

        // Copy all the date excluding the microseconds and the Z.
        // Current date: 2015-09-10T00:00:00.184968Z
        // Will become:  2015-09-10T00:00:00
        // Unit test F
        else if (originalString[19] == '.' && originalString[originalLength - 1] == 'Z') {
            strncpy(currentString, originalString, 19);
        }

        // Copy all the date excluding the miliseconds.
        // Current date: 2016-01-09T00:00:00.00
        // Will become:  2016-01-09T00:00:00
        // Unit test J
        else if (originalLength == 22 && originalString[19] == '.') {
            strncpy(currentString, originalString, 19);
            hasCentiseconds = YES;
        }

        // Poorly formatted timezone
        else {
            strncpy(currentString, originalString, originalLength > 24 ? 24 : originalLength);
        }

        // Timezone
        size_t currentLength = strlen(currentString);
        if (hasTimezone) {
            // Add the first part of the removed timezone to the end of the string.
            // Orignal date: 2015-06-23T14:40:08.000+02:00
            // Current date: 2015-06-23T14:40:08
            // Will become:  2015-06-23T14:40:08+02
            strncpy(currentString + currentLength, originalString + originalLength - 6, 3);

            // Add the second part of the removed timezone to the end of the string.
            // Original date: 2015-06-23T14:40:08.000+02:00
            // Current date:  2015-06-23T14:40:08+02
            // Will become:   2015-06-23T14:40:08+0200
            strncpy(currentString + currentLength + 3, originalString + originalLength - 2, 2);
        } else {
            // Add GMT timezone to the end of the string
            // Current date: 2015-09-10T00:00:00
            // Will become:  2015-09-10T00:00:00+0000
            strncpy(currentString + currentLength, "+0000", 5);
        }

        // Add null terminator
        currentString[sizeof(currentString) - 1] = 0;

        // Parse the formatted date using `strptime`.
        // %F: Equivalent to %Y-%m-%d, the ISO 8601 date format
        //  T: The date, time separator
        // %T: Equivalent to %H:%M:%S
        // %z: An RFC-822/ISO 8601 standard timezone specification
        struct tm tm;
        if (strptime(currentString, "%FT%T%z", &tm) == NULL) {
            return nil;
        }

        time_t timeStruct = mktime(&tm);
        double time = (double)timeStruct;

        if (hasCentiseconds || hasMiliseconds || hasMicroseconds) {
            NSString *trimmedDate = [dateString substringFromIndex:@"2015-09-10T00:00:00.".length];

            if (hasCentiseconds) {
                NSString *centisecondsString = [trimmedDate substringToIndex:@"00".length];
                double centiseconds = centisecondsString.doubleValue / 100.0;
                time += centiseconds;
            }

            if (hasMiliseconds) {
                NSString *milisecondsString = [trimmedDate substringToIndex:@"000".length];
                double miliseconds = milisecondsString.doubleValue / 1000.0;
                time += miliseconds;
            }

            if (hasMicroseconds) {
                NSString *microsecondsString = [trimmedDate substringToIndex:@"000000".length];
                double microseconds = microsecondsString.doubleValue / 1000000.0;
                time += microseconds;
            }
        }

        return [NSDate dateWithTimeIntervalSince1970:time];
    }

    NSAssert1(NO, @"Failed to parse date: %@", dateString);
    return nil;
}

+ (NSDate *)dateFromUnixTimestampNumber:(NSNumber *)unixTimestamp {
    return [self dateFromUnixTimestampString:[unixTimestamp stringValue]];
}

+ (NSDate *)dateFromUnixTimestampString:(NSString *)unixTimestamp {
    NSString *parsedString = unixTimestamp;

    NSString *validUnixTimestamp = @"1441843200";
    NSInteger validLength = [validUnixTimestamp length];
    if ([unixTimestamp length] > validLength) {
        parsedString = [unixTimestamp substringToIndex:validLength];
    }

    NSNumberFormatter *numberFormatter = [NSNumberFormatter new];
    numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    NSNumber *unixTimestampNumber = [numberFormatter numberFromString:parsedString];
    NSDate *date = [[NSDate alloc] initWithTimeIntervalSince1970:unixTimestampNumber.doubleValue];

    return date;
}

@end

@implementation NSString (Parser)

- (DateType)dateType {
    if ([self containsString:@"-"]) {
        return iso8601;
    } else {
        return unixTimestamp;
    }
}

@end
