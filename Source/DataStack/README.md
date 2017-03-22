![DataStack](https://raw.githubusercontent.com/SyncDB/DataStack/master/Images/datastack-logo2.png)

**DataStack** helps you to alleviate the Core Data boilerplate. Now you can go to your AppDelegate remove all the Core Data related code and replace it with an instance of DataStack ([ObjC](https://github.com/SyncDB/DATAStack/blob/master/DemoObjectiveC/AppDelegate.m), [Swift](https://github.com/SyncDB/DATAStack/blob/master/DemoSwift/AppDelegate.swift)).

- Easier thread safety
- Runs synchronously when using unit tests
- No singletons
- SQLite and InMemory support out of the box
- Easy database drop method
- Shines with Swift
- Compatible with Objective-C
- Free

## Table of Contents

* [Running the demos](#running-the-demos)
* [Initialization](#initialization)
* [Main Thread NSManagedObjectContext](#main-thread-nsmanagedobjectcontext)
* [Background Thread NSManagedObjectContext](#background-thread-nsmanagedobjectcontext)
* [Clean up](#clean-up)
* [Testing](#testing)
* [Migrations](#migrations)

## Initialization

You can easily initialize a new instance of **DataStack** with just your Core Data Model name (xcdatamodel).

**Swift**
``` swift
let dataStack = DataStack(modelName:"MyAppModel")
```

**Objective-C**
``` objc
DataStack *dataStack = [[DataStack alloc] initWithModelName:@"MyAppModel"];
```

There are plenty of other ways to intialize a DataStack:

- Using a custom store type.

``` swift
let dataStack = DataStack(modelName:"MyAppModel", storeType: .InMemory)
```

- Using another bundle and a store type, let's say your test bundle and .InMemory store type, perfect for running unit tests.

``` swift
let dataStack = DataStack(modelName: "Model", bundle: NSBundle(forClass: Tests.self), storeType: .InMemory)
```

- Using a different name for your .sqlite file than your model name, like `CustomStoreName.sqlite`.

``` swift
let dataStack = DataStack(modelName: "Model", bundle: NSBundle.mainBundle(), storeType: .SQLite, storeName: "CustomStoreName")
```

- Providing a diferent container url, by default we'll use the documents folder, most apps do this, but if you want to share your sqlite file between your main app and your app extension you'll want this.

``` swift
let dataStack = DataStack(modelName: "Model", bundle: NSBundle.mainBundle(), storeType: .SQLite, storeName: "CustomStoreName", containerURL: sharedURL)
```

## Main Thread NSManagedObjectContext

Getting access to the NSManagedObjectContext attached to the main thread is as simple as using the `mainContext` property.

```swift
self.dataStack.mainContext
```

or

```swift
self.dataStack.viewContext
```

## Background Thread NSManagedObjectContext

You can easily create a new background NSManagedObjectContext for data processing. This block is completely asynchronous and will be run on a background thread.

To be compatible with NSPersistentContainer you can also use `performBackgroundTask` instead of `performInNewBackgroundContext`.

**Swift**
```swift
func createUser() {
    self.dataStack.performInNewBackgroundContext { backgroundContext in
        let entity = NSEntityDescription.entityForName("User", inManagedObjectContext: backgroundContext)!
        let object = NSManagedObject(entity: entity, insertIntoManagedObjectContext: backgroundContext)
        object.setValue("Background", forKey: "name")
        object.setValue(NSDate(), forKey: "createdDate")
        try! backgroundContext.save()
    }
}
```

**Objective-C**
```objc
- (void)createUser {
    [self.dataStack performInNewBackgroundContext:^(NSManagedObjectContext * _Nonnull backgroundContext) {
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:backgroundContext];
        NSManagedObject *object = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:backgroundContext];
        [object setValue:@"Background" forKey:@"name"];
        [object setValue:[NSDate date] forKey:@"createdDate"];
        [backgroundContext save:nil];
    }];
}
```

When using Xcode's Objective-C autocompletion the `backgroundContext` parameter name doesn't get included. Make sure to add it.

## Clean up

Deleting the `.sqlite` file and resetting the state of your **DataStack** is as simple as just calling `drop`.

**Swift**
```swift
self.dataStack.drop()
```

**Objective-C**
```objc
[self.dataStack forceDrop];
```

## Testing

**DataStack** is optimized for unit testing and it runs synchronously in testing environments. Hopefully you'll have to use less XCTestExpectations now.

You can create a stack that uses in memory store like this if your Core Data model is located in your app bundle:

**Swift**
```swift
let dataStack = DataStack(modelName: "MyAppModel", bundle: NSBundle.mainBundle(), storeType: .InMemory)
```

**Objective-C**
```objc
DataStack *dataStack = [[DataStack alloc] initWithModelName:@"MyAppModel"
                                                     bundle:[NSBundle mainBundle]
                                                  storeType:DataStackStoreTypeInMemory];
```

If your Core Data model is located in your test bundle:

**Swift**
```swift
let dataStack = DataStack(modelName: "MyAppModel", bundle: NSBundle(forClass: Tests.self), storeType: .InMemory)
```

**Objective-C**
```objc
DataStack *dataStack = [[DataStack alloc] initWithModelName:@"MyAppModel"
                                                     bundle:[NSBundle bundleForClass:[self class]]
                                                  storeType:DataStackStoreTypeInMemory];
```

_(Hint: Maybe you haven't found the best way to use NSFetchedResultsController, well [here it is](https://github.com/SyncDB/DATASource).)_

## Migrations

If `DataStack` has troubles creating your persistent coordinator because a migration wasn't properly handled it will destroy your data and create a new sqlite file. The normal Core Data behaviour for this is making your app crash on start. This is not fun.
