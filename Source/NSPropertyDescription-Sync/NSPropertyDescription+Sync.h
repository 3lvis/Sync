@import CoreData;

@interface NSPropertyDescription (Sync)

@property (readonly) BOOL isCustomPrimaryKey;

@property (nonatomic, nullable, readonly) NSString *customKey;

@end
