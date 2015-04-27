@import CoreData;

NS_ASSUME_NONNULL_BEGIN

@class DATAStack;

@interface Sync : NSObject

+ (void)changes:(NSArray *)changes
  inEntityNamed:(NSString *)entityName
      dataStack:(DATAStack *)dataStack
     completion:(void (^ __nullable)(NSError * __nullable error))completion;

+ (void)changes:(NSArray *)changes
  inEntityNamed:(NSString *)entityName
      predicate:(nullable NSPredicate *)predicate
      dataStack:(DATAStack *)dataStack
     completion:(void (^ __nullable)(NSError * __nullable error))completion;

+ (void)changes:(NSArray *)changes
  inEntityNamed:(NSString *)entityName
         parent:(NSManagedObject *)parent
      dataStack:(DATAStack *)dataStack
     completion:(void (^ __nullable)(NSError * __nullable error))completion;

+ (void)changes:(NSArray *)changes
  inEntityNamed:(NSString *)entityName
      predicate:(nullable NSPredicate *)predicate
         parent:(nullable NSManagedObject *)parent
      inContext:(NSManagedObjectContext *)context
      dataStack:(DATAStack *)dataStack
     completion:(void (^ __nullable)(NSError * __nullable error))completion;

@end

NS_ASSUME_NONNULL_END
