@import CoreData;

@interface NSPropertyDescription (Sync)

@property (readonly) BOOL isCustomPrimaryKey;

@property (nonatomic, nullable, readonly) NSString *customKey;

@property (readonly) BOOL shouldExportAttribute;

@property (nonatomic, nullable, readonly) NSString *customTransformerName;

@end
