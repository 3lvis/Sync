@import CoreData;

@class DATAStack;

@interface Kipu : NSObject

+ (void)processChanges:(NSArray *)changes
       usingEntityName:(NSString *)entityName
             dataStack:(DATAStack *)dataStack
            completion:(void (^)(NSError *error))completion;

+ (void)processChanges:(NSArray *)changes
       usingEntityName:(NSString *)entityName
             predicate:(NSPredicate *)predicate
             dataStack:(DATAStack *)dataStack
            completion:(void (^)(NSError *error))completion;

+ (void)processChanges:(NSArray *)changes
       usingEntityName:(NSString *)entityName
                parent:(NSManagedObject *)parent
             dataStack:(DATAStack *)dataStack
            completion:(void (^)(NSError *error))completion;

@end
