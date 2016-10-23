![Sync](https://raw.githubusercontent.com/SyncDB/Sync/master/Images/logo-v3.png)

<div align = "center">
  <a href="https://cocoapods.org/pods/Sync">
    <img src="https://img.shields.io/cocoapods/v/Sync.svg?style=flat" />
  </a>
  <a href="https://github.com/SyncDB/Sync">
    <img src="https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat" />
  </a>
  <a href="https://github.com/SyncDB/Sync#installation">
    <img src="https://img.shields.io/badge/compatible-swift%202.3%20and%203.0-orange.svg" />
  </a>
</div>

<div align = "center">
  <a href="https://cocoapods.org/pods/Sync" target="blank">
    <img src="https://img.shields.io/cocoapods/p/Sync.svg?style=flat" />
  </a>
  <a href="https://cocoapods.org/pods/Sync" target="blank">
    <img src="https://img.shields.io/cocoapods/l/Sync.svg?style=flat" />
  </a>
  <a href="https://gitter.im/SyncDB/Sync">
    <img src="https://img.shields.io/gitter/room/nwjs/nw.js.svg" />
  </a>
  <br>
  <br>
</div>

**Sync** eases your everyday job of parsing a JSON response and getting it into Core Data. It uses a convention-over-configuration paradigm to facilitate your workflow.

Syncing JSON to Core Data is a repetitive tasks that often demands adding a lot of boilerplate code. Mapping attributes, mapping relationships, diffing for inserts, removals and updates are often tasks that don't change between apps. Taking this in account we took the challenge to abstract this into a library. **Sync** uses the knowledge of your Core Data model to infer all the mapping between your JSON and Core Data, once you use it, it feels so obvious that you'll wonder why you weren't doing this before.

* Automatic mapping of camelCase or snake_case JSON into Core Data
* Handles operations in safe background threads
* Thread-safe saving, we handle retrieving and storing objects in the right threads
* Diffing of changes, updated, inserted and deleted objects (which are automatically purged for you)
* Auto-mapping of relationships (one-to-one, one-to-many and many-to-many)
* Smart-updates, only updates your `NSManagedObject`s if the server values are different from your local ones
* Uniquing, one Core Data entry per primary key
* `NSOperation` subclass, any Sync process can be queued and cancelled at any time!

## Table of Contents

* [Basic example](#basic-example)
* [More examples](#more-examples)
* [Getting Started](#getting-started)
  * [Installation](#installation)
* [Requisites](#requisites)
  * [Core Data Stack](#core-data-stack)
  * [Primary Key](#primary-key)
  * [Attribute Mapping](#attribute-mapping)
  * [Attribute Types](#attribute-types)
  * [Relationship Mapping](#relationship-mapping)
    * [One-to-many](#one-to-many)
    * [One-to-many (simplified)](#one-to-many-simplified)
    * [One-to-one](#one-to-one)
    * [One-to-one (simplified)](#one-to-one-simplified)
  * [Networking](#networking)
  * [Supported iOS, OS X, watchOS and tvOS Versions](#supported-ios-os-x-watchos-and-tvos-versions)
* [Components](#components)
* [FAQ](#faq)
* [Credits](#credits)
* [License](#license)

## Basic example

### Interface

```swift
Sync.changes(
  changes: [[String : Any]],
  inEntityNamed: String,
  dataStack: DATAStack,
  completion: ((NSError?) -> Void)?)
```

* `changes`: JSON response
* `entityName`: Core Data’s Model Entity Name (such as User, Note, Task)
* `dataStack`: Your [DATAStack](https://github.com/SyncDB/DATAStack)

### Model

![Model](https://raw.githubusercontent.com/SyncDB/Sync/master/Images/one-to-many-swift.png)

### JSON

```json
[
  {
    "id": 6,
    "name": "Shawn Merrill",
    "email": "shawn@ovium.com",
    "created_at": "2014-02-14T04:30:10+00:00",
    "updated_at": "2014-02-17T10:01:12+00:00",
    "notes": [
      {
        "id": 0,
        "text": "Shawn Merril's diary, episode 1",
        "created_at": "2014-03-11T19:11:00+00:00",
        "updated_at": "2014-04-18T22:01:00+00:00"
      }
    ]
  }
]
```

### Sync

```swift
Sync.changes(
  changes: JSON,
  inEntityNamed: "User",
  dataStack: dataStack) { error in
    // New objects have been inserted
    // Existing objects have been updated
    // And not found objects have been deleted
}
```

Alternatively, if you only want to sync users that have been created in the last 24 hours, you could do this by using a `NSPredicate`.

```swift
let now = NSDate()
let yesterday = now.dateByAddingTimeInterval(-24*60*60)
let predicate = NSPredicate(format:@"createdAt > %@", yesterday)

Sync.changes(
  changes: JSON,
  inEntityNamed: "User",
  predicate: predicate
  dataStack: dataStack) { error in
    //..
}
```

## More Examples

<a href="https://github.com/SyncDB/AppNetDemo">
  <img src="https://raw.githubusercontent.com/SyncDB/Sync/master/Images/APPNET-v3.png" />
</a>

<a href="https://github.com/SyncDB/DesignerNewsDemo">
  <img src="https://raw.githubusercontent.com/SyncDB/Sync/master/Images/DN-v4.png" />
</a>


## Getting Started

### Installation

**Sync** is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

#### Swift 2.3
```ruby
pod 'Sync', '~> 1'
```

#### Swift 3
```ruby
pod 'Sync', '~> 2'
```

**Sync** is also available through [Carthage](https://github.com/Carthage/Carthage). To install
it, simply add the following line to your Cartfile:

```ruby
github "SyncDB/Sync" ~> 2.0
```

## Requisites

### Core Data Stack

Replace your Core Data stack with an instance of [DATAStack](https://github.com/SyncDB/DATAStack).

```swift
self.dataStack = DATAStack(modelName: "Demo")
```

### Primary key

Sync requires your entities to have a primary key, this is important for diffing, otherwise Sync doesn’t know how to differentiate between entries.

By default **Sync** uses `id` from the JSON and `id` (or `remoteID`) from Core Data as the primary key.

You can mark any attribute as primary key by adding `hyper.isPrimaryKey` and the value `true` (or `YES`). For example, in our [Designer News](https://github.com/SyncDB/DesignerNewsDemo) project we have a `Comment` entity that uses `body` as the primary key.

![Custom primary key](https://raw.githubusercontent.com/SyncDB/Sync/master/Images/custom-primary-key-v3.png)

If you add the flag `hyper.isPrimaryKey` to the attribute `contractID` then:

- Local primary key will be: `contractID`
- Remote primary key will be: `contract_id`

If you want to use `id` for the remote primary key you also have to add the flag `hyper.remoteKey` and write `id` as the value.

- Local primary key will be: `articleBody`
- Remote primary key will be: `id`

### Attribute Mapping

Your attributes should match their JSON counterparts in `camelCase` notation instead of `snake_case`. For example `first_name` in the JSON maps to `firstName` in Core Data and `address` in the JSON maps to `address` in Core Data.

There are some exception to this rule:

* Reserved attributes should be prefixed with the `entityName` (`type` becomes `userType`, `description` becomes `userDescription` and so on). In the JSON they don't need to change, you can keep `type` and `description` for example. A full list of reserved attributes can be found [here](https://github.com/SyncDB/SYNCPropertyMapper/blob/master/Source/NSManagedObject%2BHYPPropertyMapper.m#L265)
* Attributes with acronyms will be normalized (`id`, `pdf`, `url`, `png`, `jpg`, `uri`, `json`, `xml`). For example `user_id` will be mapped to `userID` and so on. You can find the entire list of supported acronyms [here](https://github.com/SyncDB/NSString-HYPNetworking/blob/master/README.md#acronyms).

If you want to map your Core Data attribute with a JSON attribute that has different naming, you can do by adding `hyper.remoteKey` in the user info box with the value you want to map.

![Custom remote key](https://raw.githubusercontent.com/SyncDB/Sync/master/Images/custom-remote-key-v2.png)

### Attribute Types

#### Array/Dictionary

To map **arrays** or **dictionaries** just set attributes as `Binary Data` on the Core Data modeler.

![screen shot 2015-04-02 at 11 10 11 pm](https://cloud.githubusercontent.com/assets/1088217/6973785/7d3767dc-d98d-11e4-8add-9c9421b5ed47.png)

#### Retrieving mapped arrays

```json
{
  "hobbies": [
    "football",
    "soccer",
    "code"
  ]
}
```

```swift
let hobbies = NSKeyedUnarchiver.unarchiveObjectWithData(managedObject.hobbies)
// ==> "football", "soccer", "code"
```

#### Retrieving mapped dictionaries
```json
{
  "expenses" : {
    "cake" : 12.50,
    "juice" : 0.50
  }
}
```

```swift
let expenses = NSKeyedUnarchiver.unarchiveObjectWithData(managedObject.expenses)
// ==> "cake" : 12.50, "juice" : 0.50
```

#### Dates

We went for supporting [ISO8601](http://en.wikipedia.org/wiki/ISO_8601) and unix timestamp out of the box because those are the most common formats when parsing dates, also we have a [quite performant way to parse this strings](https://github.com/SyncDB/SYNCPropertyMapper/blob/master/Source/NSManagedObject%2BHYPPropertyMapper.m#L272-L319) which overcomes the [performance issues of using `NSDateFormatter`](http://blog.soff.es/how-to-drastically-improve-your-app-with-an-afternoon-and-instruments/).

```swift
let values = ["created_at" : "2014-01-01T00:00:00+00:00",
              "updated_at" : "2014-01-02",
              "published_at": "1441843200"
              "number_of_attendes": 20]

managedObject.hyp_fill(values)

let createdAt = managedObject.value(forKey: "createdAt")
// ==> "2014-01-01 00:00:00 +00:00"

let updatedAt = managedObject.value(forKey: "updatedAt")
// ==> "2014-01-02 00:00:00 +00:00"

let publishedAt = managedObject.value(forKey: "publishedAt")
// ==> "2015-09-10 00:00:00 +00:00"
```

#### JSON representation from a NSManagedObject

**Sync**'s dependency [**SYNCPropertyMapper**](https://github.com/SyncDB/SYNCPropertyMapper) provides a method to generate a JSON object from any NSManagedObject instance. [More information here.](https://github.com/SyncDB/SYNCPropertyMapper#json-representation-from-a-nsmanagedobject)

### Relationship mapping

**Sync** will map your relationships to their JSON counterparts. In the [Example](#example-with-snake_case-in-swift) presented at the beginning of this document you can see a very basic example of relationship mapping.

#### One-to-many

Lets consider the following Core Data model.

![One-to-many](https://raw.githubusercontent.com/SyncDB/Sync/master/Images/one-to-many-swift.png)

This model has a one-to-many relationship between `User` and `Note`, so in other words a user has many notes. Here can also find an inverse relationship to user on the Note model. This is required for Sync to have more context on how your models are presented. Finally, in the Core Data model there is a cascade relationship between user and note, so when a user is deleted all the notes linked to that user are also removed (you can specify any delete rule).

So when Sync, looks into the following JSON, it will sync all the notes for that specific user, doing the necessary inverse relationship dance.

```json
[
  {
    "id": 6,
    "name": "Shawn Merrill",
    "notes": [
      {
        "id": 0,
        "text": "Shawn Merril's diary, episode 1",
      }
    ]
  }
]
```

#### One-to-many Simplified

As you can see this procedures require the full JSON object to be included, but when working with APIs, sometimes you already have synced all the required items. Sync supports this too.

For example, in the one-to-many example, you have a user, that has many notes. If you already have synced all the notes then your JSON would only need the `notes_ids`, this can be an array of strings or integers. As a sidenote only do this if you are 100% sure that all the required items (notes) have been synced, otherwise this relationships will get ignored and an error will be logged. Also if you want to remove all the notes from a user, just provide `"notes_ids": null` and **Sync** will do the clean up for you.

```json
[
  {
    "id": 6,
    "name": "Shawn Merrill",
    "notes_ids": [0, 1, 2]
  }
]
```

#### One-to-one

A similar procedure is applied to one-to-one relationships. For example lets say you have the following model:

![one-to-one](https://raw.githubusercontent.com/SyncDB/Sync/master/Images/one-to-one-v2.png)

This model is simple, a user as a company. A compatible JSON would look like this:

```json
[
  {
    "id": 6,
    "name": "Shawn Merrill",
    "company": {
      "id": 0,
      "text": "Facebook",
    }
  }
]
```

#### One-to-one Simplified

As you can see this procedures require the full JSON object to be included, but when working with APIs, sometimes you already have synced all the required items. Sync supports this too.

For example, in the one-to-one example, you have a user, that has one company. If you already have synced all the companies then your JSON would only need the `company_id`. As a sidenote only do this if you are 100% sure that all the required items (companies) have been synced, otherwise this relationships will get ignored and an error will be logged. Also if you want to remove the company from the user, just provide `"company_id": null` and **Sync** will do the clean up for you.

```json
[
  {
    "id": 6,
    "name": "Shawn Merrill",
    "company_id": 0
  }
]
```

### Networking

You are free to use any networking library.

### Supported iOS, OS X, watchOS and tvOS Versions

- iOS 8 or above
- OS X 10.9 or above
- watchOS 2.0 or above
- tvOS 9.0 or above

## Components

**Sync** wouldn’t be possible without the help of this *fully tested* components:

* [**DATAStack**](https://github.com/SyncDB/DATAStack): Core Data stack and thread safe saving

* [**DATAFilter**](https://github.com/SyncDB/DATAFilter): Helps you purge deleted objects. Internally we use it to diff inserts, updates and deletes. Also it’s used for uniquing Core Data does this based on objectIDs, DATAFilter uses your remote keys (such as id) for this

* [**SYNCPropertyMapper**](https://github.com/SyncDB/SYNCPropertyMapper): Maps JSON fields with their Core Data counterparts, it does most of it’s job using the paradigm “_convention over configuration_”

## FAQ

#### How uniquing works (many-to-many, one-to-many)?

In a `one-to-many` relationship IDs are unique for a parent, but not between parents. For example in this example we have a list of posts where each post has many comments. When syncing posts 2 comment entries will be created:

````json
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

This means that the local primary key was not found, Sync uses `id` (or `remoteID`) by default, but if you have another local primary key make sure to mark it with `"hyper.isPrimaryKey" : "true"` in your attribute's user info. For more information check the [Primary Key](https://github.com/SyncDB/Sync#primary-key) section.

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
Sync.changes(firstBatch, inEntityNamed: "User", dataStack: dataStack, operations: [.All]) {
    // All users have been imported, they are happy
}

let secondImport = // Second import of users
Sync.changes(secondImport, inEntityNamed: "User", dataStack: dataStack, operations: [.Insert, .Update]) {
    // Likely after some changes have happened, here usually Sync would remove the not found items but this time
    // new users have been imported, existing users have been updated, and not found users have been ignored
}
```

#### How can I load tens of thousands of objects without blocking my UI?

Saving to a background context or a main context could still block the UI since merging to the main thread is a task that of course is done in the main thread. Luckily `DATAStack` has a `newNonMergingBackgroundContext` context that helps us to perform saves without hitting the main thread and any point. If you want to load new items, let's say using a `NSFetchedResultController` you can do it like this:

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

## License

**Sync** is available under the MIT license. See the [LICENSE](https://github.com/SyncDB/Sync/blob/master/LICENSE.md) file for more info.
