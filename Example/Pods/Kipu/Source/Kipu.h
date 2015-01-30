@import CoreData;

@class ANDYDataStack;

@interface Kipu : NSObject

+ (void)processChanges:(NSArray *)changes
       usingEntityName:(NSString *)entityName
             dataStack:(ANDYDataStack *)dataStack
            completion:(void (^)(NSError *error))completion;

+ (void)processChanges:(NSArray *)changes
       usingEntityName:(NSString *)entityName
             predicate:(NSPredicate *)predicate
             dataStack:(ANDYDataStack *)dataStack
            completion:(void (^)(NSError *error))completion;

+ (void)processChanges:(NSArray *)changes
       usingEntityName:(NSString *)entityName
                parent:(NSManagedObject *)parent
             dataStack:(ANDYDataStack *)dataStack
            completion:(void (^)(NSError *error))completion;

+ (void)processChanges:(NSArray *)changes
       usingEntityName:(NSString *)entityName
             predicate:(NSPredicate *)predicate
                parent:(NSManagedObject *)parent
             inContext:(NSManagedObjectContext *)context
            completion:(void (^)(NSError *error))completion;

@end
