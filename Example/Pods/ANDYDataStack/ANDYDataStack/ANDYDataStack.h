@import Foundation;
@import CoreData;


typedef NS_ENUM(NSInteger, ANDYDataStoreType) {
    ANDYDataInMemoryStoreType = 0,
    ANDYDataSQLiteStoreType
};

@interface ANDYDataStack : NSObject

/*!
 * @discussion Creates an instance of ANDYDataStack with SQLiteStoreType using the app's name as a Core Data model name.
 * @return An instance of @c ANDYDataStack or @c nil if the model is not found.
 */
- (instancetype)init;

/*!
 * @discussion Creates an instance of ANDYDataStack with SQLiteStoreType.
 * @param modelName The name of the Core Data model.
 * @return An instance of @c ANDYDataStack or @c nil if the model is not found.
 */
- (instancetype)initWithModelName:(NSString *)modelName;

/*!
 * @discussion Creates an instance of ANDYDataStack with SQLiteStoreType.
 * @param modelName The name of the Core Data model.
 * @param bundle The bundle where the Core Data model is located.
 * @param storeType The store type, either @c SQLite or @c InMemory.
 * @return An instance of @c ANDYDataStack or @c nil if the model is not found.
 */
- (instancetype)initWithModelName:(NSString *)modelName
                           bundle:(NSBundle *)bundle
                        storeType:(ANDYDataStoreType)storeType NS_DESIGNATED_INITIALIZER;

/*!
 * Provides a NSManagedObjectContext appropriate for use on the main
 * thread.
 */
@property (strong, nonatomic, readonly) NSManagedObjectContext *mainThreadContext;

/*!
 * Provides a safe way to perform an operation in a background
 * operation by using a context.
 */
- (void)performInBackgroundThreadContext:(void (^)(NSManagedObjectContext *context))operation;

/*!
 * Provides a new private context bound to the mainThreadContext for a
 * performant background operation.
 * \returns A background NSManagedObjectContext.
 */
- (NSManagedObjectContext *)backgroundThreadContext;

/*!
 * Saves current state of mainContext into the database.
 */
- (void)persistContext;

/*!
 * Destroys state of ANDYDataStack.
 */
- (void)destroy;

@end
