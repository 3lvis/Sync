//
//  ANDYDataManager.m
//  Andy
//
//  Created by Elvis Nunez on 10/29/13.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import "ANDYDataManager.h"
@import UIKit;

@interface ANDYDataManager ()
@property (strong, nonatomic, readwrite) NSManagedObjectContext *mainContext;
@property (strong, nonatomic) NSManagedObjectContext *writerContext;
@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic) BOOL inMemoryStore;
@end

@implementation ANDYDataManager

+ (void)setUpStackWithInMemoryStore
{
    [[self sharedManager] setInMemoryStore:YES];
}

+ (ANDYDataManager *)sharedManager
{
    static ANDYDataManager *__sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __sharedInstance = [[ANDYDataManager alloc] init];
    });
    
    return __sharedInstance;
}

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
    NSManagedObjectContext *managedObjectContext = self.mainContext;
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
    NSManagedObjectContext *managedObjectContext = self.mainContext;
    
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
    NSManagedObjectContext *managedObjectContext = self.mainContext;
    
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

- (NSManagedObjectContext *)mainContext
{
    if (_mainContext) {
        return _mainContext;
    }

    _mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    _mainContext.undoManager = nil;
    _mainContext.parentContext = self.writerContext;
    [self setUpSaveNotificationForContext:_mainContext];
    return _mainContext;
}

- (NSManagedObjectContext *)writerContext
{
    if (_writerContext) {
        return _writerContext;
    }

    _writerContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    _writerContext.undoManager = nil;
    [_writerContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
    return _writerContext;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:[self appName] withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = nil;
    
    NSString *filePath = [NSString stringWithFormat:@"%@.sqlite", [self appName]];
    storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:filePath];
    
    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption: @YES, NSInferMappingModelAutomaticallyOption: @YES};
    
    NSString *storeType = (self.inMemoryStore) ? NSInMemoryStoreType : NSSQLiteStoreType;
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

- (NSString *)appName
{
    NSString *string = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
    NSString *trimmedString = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    return trimmedString;
}

#pragma mark - Class methods

+ (void)performInBackgroundContext:(void (^)(NSManagedObjectContext *context))operation
{
    NSManagedObjectContext *context = [self backgroundContext];
    [context performBlock:^{
        if (operation) {
            operation(context);
        }
    }];
}

+ (NSManagedObjectContext *)backgroundContext
{
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.persistentStoreCoordinator = [[self sharedManager] persistentStoreCoordinator];
    context.undoManager = nil;
    [[NSNotificationCenter defaultCenter] addObserver:[self sharedManager]
                                             selector:@selector(backgroundThreadDidSave:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:context];
    return context;
}

- (void)backgroundThreadDidSave:(NSNotification *)notification
{
    if ([NSThread isMainThread]) {
        [NSException raise:@"ANDY_BACKGROUND_THREAD_CREATION_EXCEPTION"
                    format:@"Background context saved in the main thread. Use context's `performBlock`"];
    } else {
        // sync changes made on the background thread's context to the main thread's context
        [self.mainContext performBlock:^(){
            [self.mainContext mergeChangesFromContextDidSaveNotification:notification];
        }];
    }
}

#pragma mark - Test

- (void)reset
{
    NSPersistentStore *store = [self.persistentStoreCoordinator.persistentStores lastObject];
    NSURL *storeURL = store.URL;

    self.writerContext = nil;
    self.mainContext = nil;
    self.managedObjectModel = nil;
    self.persistentStoreCoordinator = nil;
    self.inMemoryStore = NO;

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    if ([fileManager fileExistsAtPath:storeURL.path])
        [fileManager removeItemAtURL:storeURL error:&error];
    if (error) {
        NSLog(@"error deleting sqlite file");
        abort();
    }
}

@end
