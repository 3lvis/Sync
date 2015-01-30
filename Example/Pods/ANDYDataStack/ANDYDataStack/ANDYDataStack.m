#import "ANDYDataStack.h"

@import UIKit;

@interface ANDYDataStack ()

@property (strong, nonatomic, readwrite) NSManagedObjectContext *mainThreadContext;
@property (strong, nonatomic) NSManagedObjectContext *writerContext;
@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic) ANDYDataStoreType storeType;
@property (nonatomic, copy) NSString *modelName;
@property (nonatomic, strong) NSBundle *modelBundle;

@end

@implementation ANDYDataStack

- (instancetype)init
{
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *bundleName = [[bundle infoDictionary] objectForKey:@"CFBundleName"];

    return [self initWithModelName:bundleName];
}

- (instancetype)initWithModelName:(NSString *)modelName
{
    NSBundle *bundle = [NSBundle mainBundle];

    return [self initWithModelName:modelName
                            bundle:bundle
                         storeType:ANDYDataSQLiteStoreType];
}

- (instancetype)initWithModelName:(NSString *)modelName
                           bundle:(NSBundle *)bundle
                        storeType:(ANDYDataStoreType)storeType
{
    self = [super init];
    if (!self) return nil;

    _modelName = modelName;
    _modelBundle = bundle;
    _storeType = storeType;

    return self;
}

#pragma mark - Private methods

- (void)setUpSaveNotificationForContext:(NSManagedObjectContext *)context
{
    [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification
                                                      object:context
                                                       queue:nil
                                                  usingBlock:^(NSNotification *notification) {
                                                      if (![NSThread isMainThread]) {
                                                          [NSException raise:@"ANDY_MAIN_THREAD_CREATION_EXCEPTION"
                                                                      format:@"Main context saved in background thread. Use context's `performBlock`"];
                                                      } else {
                                                          if (![notification.object isEqual:context]) {
                                                              [context performBlock:^(){
                                                                  [context mergeChangesFromContextDidSaveNotification:notification];
                                                              }];
                                                          }
                                                      }
                                                  }];
}

- (void)saveContext
{
    NSManagedObjectContext *managedObjectContext = self.mainThreadContext;
    [managedObjectContext performBlock:^{
        if (managedObjectContext != nil) {
            NSError *error = nil;
            if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                abort();
            }
        }
    }];
}

- (void)persistContext
{
    NSManagedObjectContext *writerManagedObjectContext = self.writerContext;
    NSManagedObjectContext *managedObjectContext = self.mainThreadContext;

    [managedObjectContext performBlock:^{
        NSError *error = nil;
        if ([managedObjectContext save:&error]) {
            [writerManagedObjectContext performBlock:^{
                NSError *parentError = nil;
                if (![writerManagedObjectContext save:&parentError]) {
                    NSLog(@"Unresolved error saving parent managed object context %@, %@", error, [error userInfo]);
                    abort();
                }
            }];
        } else {
            NSLog(@"Unresolved error saving managed object context %@, %@", error, [error userInfo]);
            abort();
        }
    }];
}

- (void)resetContext
{
    NSManagedObjectContext *writerManagedObjectContext = self.writerContext;
    NSManagedObjectContext *managedObjectContext = self.mainThreadContext;

    [managedObjectContext performBlock:^{
        [managedObjectContext reset];
        [writerManagedObjectContext performBlock:^{
            [writerManagedObjectContext reset];
        }];
    }];
}

#if !TARGET_IPHONE_SIMULATOR
- (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL
{
    return [URL setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:nil];
}
#endif

#pragma mark - Core Data stack

- (NSManagedObjectContext *)mainThreadContext
{
    if (_mainThreadContext) return _mainThreadContext;

    _mainThreadContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    _mainThreadContext.undoManager = nil;
    _mainThreadContext.parentContext = self.writerContext;
    _mainThreadContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;

    [self setUpSaveNotificationForContext:_mainThreadContext];

    return _mainThreadContext;
}

- (NSManagedObjectContext *)writerContext
{
    if (_writerContext) return _writerContext;

    _writerContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    _writerContext.undoManager = nil;
    _writerContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
    _writerContext.persistentStoreCoordinator = self.persistentStoreCoordinator;

    return _writerContext;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel) return _managedObjectModel;

    NSBundle *bundle = (self.modelBundle) ?: [NSBundle mainBundle];
    NSURL *modelURL = [bundle URLForResource:self.modelName withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];

    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator) return _persistentStoreCoordinator;

    NSURL *storeURL = nil;

    NSString *filePath = [NSString stringWithFormat:@"%@.sqlite", self.modelName];
    storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:filePath];

    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption: @YES, NSInferMappingModelAutomaticallyOption: @YES};

    NSString *storeType;

    switch (self.storeType) {
        case ANDYDataInMemoryStoreType:
            storeType = NSInMemoryStoreType;
            break;
        case ANDYDataSQLiteStoreType:
            storeType = NSSQLiteStoreType;
            break;
    }

    NSError *error = nil;

    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];

    if (![_persistentStoreCoordinator addPersistentStoreWithType:storeType
                                                   configuration:nil
                                                             URL:storeURL
                                                         options:options
                                                           error:&error]) {

        [[NSFileManager defaultManager] removeItemAtPath:storeURL.path error:nil];
        if (![_persistentStoreCoordinator addPersistentStoreWithType:storeType
                                                       configuration:nil
                                                                 URL:storeURL
                                                             options:options
                                                               error:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }

        NSString *alertTitle = NSLocalizedString(@"Error encountered while reading the database. Please allow all the data to download again.", @"[Error] Message to show when the database is corrupted");
        [[[UIAlertView alloc] initWithTitle:alertTitle
                                    message:nil
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }

#if !TARGET_IPHONE_SIMULATOR
    [self addSkipBackupAttributeToItemAtURL:storeURL];
#endif

    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                   inDomains:NSUserDomainMask] lastObject];
}

#pragma mark - Public methods

- (void)performInBackgroundThreadContext:(void (^)(NSManagedObjectContext *context))operation
{
    NSManagedObjectContext *context = [self backgroundThreadContext];
    [context performBlock:^{
        if (operation) {
            operation(context);
        }
    }];
}

- (NSManagedObjectContext *)backgroundThreadContext
{
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.persistentStoreCoordinator = self.persistentStoreCoordinator;
    context.undoManager = nil;
    context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(backgroundThreadDidSave:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:context];
    return context;
}

#pragma mark - Observers

- (void)backgroundThreadDidSave:(NSNotification *)notification
{
    if ([NSThread isMainThread]) {
        [NSException raise:@"ANDY_BACKGROUND_THREAD_CREATION_EXCEPTION"
                    format:@"Background context saved in the main thread. Use context's `performBlock`"];
    } else {
        // sync changes made on the background thread's context to the main thread's context
        [self.mainThreadContext performBlock:^(){
            [self.mainThreadContext mergeChangesFromContextDidSaveNotification:notification];
        }];
    }
}

#pragma mark - Test

- (void)destroy
{
    NSPersistentStore *store = [self.persistentStoreCoordinator.persistentStores lastObject];
    NSURL *storeURL = store.URL;

    self.writerContext = nil;
    self.mainThreadContext = nil;
    self.managedObjectModel = nil;
    self.persistentStoreCoordinator = nil;

    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSError *error = nil;
    if ([fileManager fileExistsAtPath:storeURL.path]) [fileManager removeItemAtURL:storeURL error:&error];

    if (error) {
        NSLog(@"error deleting sqlite file");
        abort();
    }
}

@end
