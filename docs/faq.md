# FAQ

#### How uniquing works (many-to-many, one-to-many)?

In a `one-to-many` relationship IDs are unique for a parent, but not between parents. For example in this example we have a list of posts where each post has many comments. When syncing posts 2 comment entries will be created:

```json
[
  {
    "id": 0,
    "title": "Story title 0",
    "comments": [
      {
        "id":0,
        "body":"Comment body"
      }
    ]
  },
  {
    "id": 1,
    "title": "Story title 1",
    "comments": [
      {
        "id":0,
        "body":"Comment body"
      }
    ]
  }
]
```

Meanwhile in a `many-to-many` relationship childs are unique across parents.

For example a author can have many documents and a document can have many authors. Here only one author will be created.

```json
[
  {
    "id": 0,
    "title": "Document name 0",
    "authors": [
      {
        "id":0,
        "name":"Michael Jackson"
      }
    ]
  },
  {
    "id": 1,
    "title": "Document name 1",
    "authors": [
      {
        "id":0,
        "body":"Michael Jackson"
      }
    ]
  }
]
```

#### Logging changes

Logging changes to Core Data is quite simple, just subscribe to changes like this and print the needed elements:

```swift
NotificationCenter.default.addObserver(self, selector: #selector(self.changeNotification), name: .NSManagedObjectContextObjectsDidChange, object: self.dataStack.mainContext)

func changeNotification(notification: NSNotification) {
    let deletedObjects = notification.userInfo[NSDeletedObjectsKey]
    let insertedObjects = notification.userInfo[NSInsertedObjectsKey]
}
```

Logging updates is a bit more complicated since this changes don't get propagated to the main context. But if you want an example on how to do this, you can check the AppNet example, [the change notifications demo is in the Networking file](https://github.com/SyncDB/AppNetDemo/blob/master/SyncAppNetDemo/Networking.swift#L27-L57).

If you're using Swift to be able to use `NSNotificationCenter` your class should be a subclass of `NSObject` or similar.

#### Crash on NSParameterAssert

This means that the local primary key was not found, Sync uses `id` (or `remoteID`) by default, but if you have another local primary key make sure to mark it with `"sync.isPrimaryKey" : "true"` in your attribute's user info. For more information check the [Primary Key](https://github.com/SyncDB/Sync#primary-key) section.

```swift
let localKey = entity.sync_localPrimaryKey()
assert(localKey != nil, "nil value")

let remoteKey = entity.sync_remotePrimaryKey()
assert(remoteKey != nil, "nil value")
```

#### How to map relationships that don't have IDs?

There are two ways you can sync a JSON object that doesn't have an `id`. You can either set one of it's [attributes as the primary key](https://github.com/SyncDB/Sync#primary-key), or you can store the JSON object as NSData, I have done this myself in a couple of apps works pretty well. You can find more information on how to store dictionaries using Sync [here](https://github.com/SyncDB/Sync#arraydictionary).

#### What if I only want inserts and updates?

You can provide the type of operations that you want too. If you don't set this parameter, insert, updates and deletes will be done.

This is how setting operations should work:

```swift
let firstImport = // First import of users
Sync.changes(firstBatch, inEntityNamed: "User", dataStack: dataStack, operations: [.all]) {
    // All users have been imported, they are happy
}

let secondImport = // Second import of users
Sync.changes(secondImport, inEntityNamed: "User", dataStack: dataStack, operations: [.insert, .update]) {
    // Likely after some changes have happened, here usually Sync would remove the not found items but this time
    // new users have been imported, existing users have been updated, and not found users have been ignored
}
```

#### How can I load tens of thousands of objects without blocking my UI?

Saving to a background context or a main context could still block the UI since merging to the main thread is a task that of course is done in the main thread. Luckily `DataStack` has a `newNonMergingBackgroundContext` context that helps us to perform saves without hitting the main thread and any point. If you want to load new items, let's say using a `NSFetchedResultController` you can do it like this:

```swift
try self.fetchedResultsController.performFetch()
```

For a full example on how to do achieve this magic syncing check the [Performance project](https://github.com/SyncDB/Performance).

#### Which date formats are supported by Sync?

Sync uses an extensive and [blazing fast ISO 8601 parser](https://github.com/SyncDB/DateParser). Here are some of the supported formats, if you don't find yours, just open and issue:

```
2014-01-02
2016-01-09T00:00:00
2014-03-30T09:13:00Z
2016-01-09T00:00:00.00
2015-06-23T19:04:19.911Z
2014-01-01T00:00:00+00:00
2015-09-10T00:00:00.184968Z
2015-09-10T00:00:00.116+0000
2015-06-23T14:40:08.000+02:00
2014-01-02T00:00:00.000000+00:00
```

#### Infinite loop in export() with relationships

If you're using export() and you get a stack overflow because of recursive calls, then is probably because somewhere in your relationships, your model is referencing a model that it's referencing the previous model and so on, then `PropertyMapper` doesn't know when to stop. For this reason we've introduced `sync.nonExportable`, this flag can be used for both fields and relationships. To fix your issue you need to add the flag to the relationship that shouldn't be exported.

[More information about excluding here.](https://github.com/SyncDB/Sync/tree/master/Source/NSManagedObject-PropertyMapper#excluding)
