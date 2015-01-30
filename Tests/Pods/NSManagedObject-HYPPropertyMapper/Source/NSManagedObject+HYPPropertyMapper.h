@import CoreData;

@interface NSManagedObject (HYPPropertyMapper)

- (void)hyp_fillWithDictionary:(NSDictionary *)dictionary;

- (NSDictionary *)hyp_dictionary;

@end
