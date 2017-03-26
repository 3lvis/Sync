# Core Data Stack

Even though the recommended Core Data stack to use Sync is the built-in DataStack, you don't have to use it. Sync uses NSManagedObjectContexts to do its work but debugging why something isn't working the way it should is much easier if you use the built-in Core Data stack.

### Sync's DataStack

Sync's DataStack is composed of one main context used for objects that will be displayed in the UI, and on-demand background contexts, created for manipulating Core Data objects.

Behind the scenes there's one persistent coordinator and one writer context, this context has a background concurrency type, meaning saving this context doesn't block the main thread.

One of the nice things about Sync's DataStack compared to other stacks or even NSPersistentContainer is that in unit-testing environments all the operations are run synchronously, this makes Sync a breeze to unit-test.

A simple instance of DataStack can be initalized like this:

```swift
let dataStack = DataStack(modelName: "MyCoreDataModel")
Sync.changes(json, inEntityNamed: "Users", dataStack: dataStack) { error in
    //...
}
```

### NSPersistentContainer

```swift
let momdModelURL = Bundle.main.url(forResource: modelName, withExtension: "momd")!
let model = NSManagedObjectModel(contentsOf: momdModelURL)!
let persistentContainer = NSPersistentContainer(name: modelName, managedObjectModel: model)
try! persistentContainer.persistentStoreCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
Sync.changes(json, inEntityNamed: "Users", predicate: nil, persistentContainer: persistentContainer) { error in
    //...
}
```

### Your own
```swift
let context = NSManagedObjectContext(concurrencyType: .private​Queue​Concurrency​Type)
context.persistentStoreCoordinator = yourPersistentStoreCoordinator

```
