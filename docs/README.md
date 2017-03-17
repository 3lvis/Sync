# Docs

## Table of Contents

* [How it works](#how-it-works)
* [Core Data Stack](#core-data-stack)
  * [Sync's DataStack](#sync-data-stack)
  * [NSPersistentContainer](#nspersistentContainer)
  * [Your own](#your-own)
* [Primary key or uniquing](#primary-key)
* [Attribute mapping](#attribute-mapping)
* [Relationship mapping](#relationship-mapping)
* [FAQ](#faq)

## How it works

Sync uses your Core Data model to infer how it will do the mapping and diffing. How the sync proccess works could be split in three parts:

- Diffing
- Relationship mapping
- Attribute mapping

### Diffing

The diffing part is the first thing is done in Sync, it separates inserted, updated and deleted items in three collections. This process is done by the [DataFilter](https://github.com/SyncDB/Sync/blob/master/Source/DataFilter/DataFilter.swift). To be able to diff our entries Sync requires a primary key and a collection of remote items for comparison. If there's a local entry with the same primary key as one from the remote collection this item will go to the updated collection, if there's a remote primary key that is not found in the database then the item will go to the inserted collection, finally, if there's an item in the database that is not found in the remote collection, then this item will go to the deleted collection. At the end of this process inserted and updated items will go back to Sync where the mapping will be done, and the items in the deleted collection will be removed from the database.

A lot of times the remote collection doesn't represent all the entries in the database for a specific entity, for example, you might have in your remote collection all the articles posted in the last day, meanwhile in your database you have all the entries posted ever. To ensure that the diffing only happens with the entries in the database that were posted in the last day Sync uses a predicate, this predicate will filter out the entries in the database that will be used for comparison.

### Relationship mapping

After going through the diffing process Sync will iterate through each entry if it's an insertion it will make a new entry in the database and fill the contents of this entry with the JSON ignoring relationships. If it's an updated entry then it will just fill the attributes.

This is the method call that we would be using for the following examples:

```swift
Sync.changes(json, inEntityNamed: "Users", dataStack: dataStack) { error in
    // Completed...
}
```

#### One-to-one

One-to-one relationships have have the following structure:

```json
[
  {
    "id": 1,
    "name": "John Appleseed",
    "company": {
      "id": 12,
      "name": "Apple"
    }
  }
]
```

Here Sync will check that in your Core Data model for the User entity there's a `to-one` relationship with the Company entity. Then it will verify that there also exists a dictionary named "company" in the JSON. After doing this  then Sync will confirm that this is indeed a `to-one` relationship mapping. After, Sync will look for an existing entry in the Company table for the primary key `12`, if there's one, it will use that to link it to the user, otherwise it will make a new Company entry and link that instead, finally it will fill all the attributes of the company with the contents of the company JSON.

#### One-to-many

```json
[
  {
    "id": 1,
    "name": "John Appleseed",
    "notes": [
      {
        "id": 12,
        "text": "List of things to remember"
      }
    ]
  }
]
```

#### Many-to-many

```json
[
  {
    "id": 1,
    "name": "John Appleseed",
    "projects": [
      {
        "id": 12,
        "name": "To-do list"
      }
    ]
  }
]
```

## Core Data Stack

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

## Primary key or uniquing

## Attribute mapping

## Relationship mapping

## FAQ
