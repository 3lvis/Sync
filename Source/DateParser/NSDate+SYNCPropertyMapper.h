@import Foundation;

NS_ASSUME_NONNULL_BEGIN

static NSString * const DateParserDateNoTimestampFormat = @"YYYY-MM-DD";
static NSString * const DateParserTimestamp = @"T00:00:00+00:00";
static NSString * const DateParserDescriptionDate = @"0000-00-00 00:00:00";

/**
 The type of date.

 - iso8601:       International date standard.
 - unixTimestamp: Number of seconds since Thursday, 1 January 1970.
 */
typedef NS_ENUM(NSInteger, DateType) {
    iso8601,
    unixTimestamp
};

@interface NSDate (SYNCPropertyMapper)

/**
 Converts the provided string into a NSDate object.

 @param dateString The string to be converted, can be a ISO 8601 date or a Unix timestamp, also known as Epoch time.

 @return The parsed date.
 */
+ (NSDate * _Nullable)dateFromDateString:(NSString *)dateString;

/**
 Converts the provided Unix timestamp into a NSDate object.

 @param unixTimestamp The Unix timestamp to be used, also known as Epoch time. This value shouldn't be more than NSIntegerMax (2,147,483,647).

 @return The parsed date.
 */
+ (NSDate * _Nullable)dateFromUnixTimestampString:(NSString *)unixTimestamp;

/**
 Converts the provided Unix timestamp into a NSDate object.

 @param unixTimestamp The Unix timestamp to be used, also known as Epoch time. This value shouldn't be more than NSIntegerMax (2,147,483,647).

 @return The parsed date.
 */
+ (NSDate * _Nullable)dateFromUnixTimestampNumber:(NSNumber *)unixTimestamp;

/**
 Converts the provided ISO 8601 string representation into a NSDate object. The ISO string can have the structure of any of the following values:
 @code
 2014-01-02
 2016-01-09T00:00:00
 2014-03-30T09:13:00Z
 2016-01-09T00:00:00.00
 2015-06-23T19:04:19.911Z
 2014-01-01T00:00:00+00:00
 2015-09-10T00:00:00.184968Z
 2015-09-10T00:00:00.116+0000
 2015-06-23T14:40:08.000+02:00
 2014-01-02T00:00:00.000000+00:00
 @endcode

 @param iso8601 The ISO 8601 date as NSString.

 @return The parsed date.
 */
+ (NSDate * _Nullable)dateFromISO8601String:(NSString *)iso8601;

@end


/**
 String extension to check wethere a string represents a ISO 8601 date or a Unix timestamp one.
 */
@interface NSString (Parser)

- (DateType)dateType;

@end

NS_ASSUME_NONNULL_END
