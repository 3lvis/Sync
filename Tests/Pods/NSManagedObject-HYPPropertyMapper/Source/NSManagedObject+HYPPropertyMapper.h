@import CoreData;

@interface NSManagedObject (HYPPropertyMapper)

- (void)hyp_fillWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)hyp_dictionary;
- (NSDictionary *)hyp_flatDictionary;

@end
