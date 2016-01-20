@import XCTest;

#import "NSJSONSerialization+ANDYJSONFile.h"
@import DATAStack;
#import "NSJSONSerialization+ANDYJSONFile.h"
@import Sync;
#import "NSManagedObject+HYPPropertyMapper.h"

@interface BaseTestCase : XCTestCase

- (id)objectsFromJSON:(NSString *)fileName;

- (DATAStack *)dataStackWithModelName:(NSString *)modelName;

- (NSInteger)countForEntity:(NSString *)entity
                  inContext:(NSManagedObjectContext *)context;

- (NSInteger)countForEntity:(NSString *)entity
                  predicate:(NSPredicate *)predicate
                  inContext:(NSManagedObjectContext *)context;

- (NSArray *)fetchEntity:(NSString *)entity
               inContext:(NSManagedObjectContext *)context;

- (NSArray *)fetchEntity:(NSString *)entity
               predicate:(NSPredicate *)predicate
               inContext:(NSManagedObjectContext *)context;

- (NSArray *)fetchEntity:(NSString *)entity
         sortDescriptors:(NSArray *)sortDescriptors
               inContext:(NSManagedObjectContext *)context;

- (NSArray *)fetchEntity:(NSString *)entity
               predicate:(NSPredicate *)predicate
         sortDescriptors:(NSArray *)sortDescriptors
               inContext:(NSManagedObjectContext *)context;
@end

@implementation BaseTestCase

- (id)objectsFromJSON:(NSString *)fileName {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    id objects = [NSJSONSerialization JSONObjectWithContentsOfFile:fileName inBundle:bundle];

    return objects;
}

- (DATAStack *)dataStackWithModelName:(NSString *)modelName {
    DATAStack *dataStack = [[DATAStack alloc] initWithModelName:modelName
                                                         bundle:[NSBundle bundleForClass:[self class]]
                                                      storeType:DATAStackStoreTypeSQLite];

    return dataStack;
}

- (NSInteger)countForEntity:(NSString *)entity
                  inContext:(NSManagedObjectContext *)context {
    return [self countForEntity:entity
                      predicate:nil
                      inContext:context];
}

- (NSInteger)countForEntity:(NSString *)entity
                  predicate:(NSPredicate *)predicate
                  inContext:(NSManagedObjectContext *)context {
    NSError *error = nil;
    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:entity];
    fetch.predicate = predicate;
    NSInteger count = [context countForFetchRequest:fetch error:&error];
    if (error) NSLog(@"countError: %@", [error description]);

    return count;
}

- (NSArray *)fetchEntity:(NSString *)entity
               inContext:(NSManagedObjectContext *)context {
    return [self fetchEntity:entity
                   predicate:nil
                   inContext:context];
}

- (NSArray *)fetchEntity:(NSString *)entity
               predicate:(NSPredicate *)predicate
               inContext:(NSManagedObjectContext *)context {
    return [self fetchEntity:entity
                   predicate:predicate
             sortDescriptors:nil
                   inContext:context];
}

- (NSArray *)fetchEntity:(NSString *)entity
         sortDescriptors:(NSArray *)sortDescriptors
               inContext:(NSManagedObjectContext *)context {
    return [self fetchEntity:entity
                   predicate:nil
             sortDescriptors:sortDescriptors
                   inContext:context];
}

- (NSArray *)fetchEntity:(NSString *)entity
               predicate:(NSPredicate *)predicate
         sortDescriptors:(NSArray *)sortDescriptors
               inContext:(NSManagedObjectContext *)context {
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:entity];
    request.predicate = predicate;
    request.sortDescriptors = sortDescriptors;
    NSError *error = nil;
    NSArray *objects = [context executeFetchRequest:request error:&error];
    if (error) NSLog(@"fetchError: %@", error);

    return objects;
}

@end
