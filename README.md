![Hyper Sync™](https://raw.githubusercontent.com/hyperoslo/Sync/master/Images/logo-v2.png)

[![Version](https://img.shields.io/cocoapods/v/Sync.svg?style=flat)](http://cocoadocs.org/docsets/Sync)
[![License](https://img.shields.io/cocoapods/l/Sync.svg?style=flat)](http://cocoadocs.org/docsets/Sync)
[![Platform](https://img.shields.io/cocoapods/p/Sync.svg?style=flat)](http://cocoadocs.org/docsets/Sync)
[![Join the chat at https://gitter.im/hyperoslo/Sync](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/hyperoslo/Sync?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

**Sync** eases your every day job of parsing a `JSON` response and getting it into Core Data. It uses a convention over configuration paradigm to facilitate your workflow.

* Handles operations in safe background threads
* Thread safe saving, we handle retrieving and storing objects in the right threads
* Diffing of changes, updated, inserted and deleted objects (which are automatically purged for you)
* Auto-mapping of relationships (one-to-one, one-to-many and many-to-many)
* Smart-updates, only updates your `NSManagedObject`s if the server values are different (useful when using `NSFetchedResultsController` delegates)
* Uniquing, Core Data does this based on `objectID`s, we use your remote key (such as `id`) for this


## Table of Contents

* [Interface](#interface)
  * [Swift](#swift)
  * [Objective-C](#objective-c)
* [Example](#example)
  * [Model](#model)
  * [JSON](#json)
  * [Sync](#sync)
  * [More examples](#more-examples)
* [Getting Started](#getting-started)
  * [Installation](#installation)
* [Requisites](#requisites)
  * [Core Data Stack](#core-data-stack)
  * [Primary Key](#primary-key)
  * [Attribute Mapping](#attribute-mapping)
  * [Attribute Types](#attribute-types)
  * [Networking](#networking)
  * [Supported iOS Versions](#supported-ios-versions)
* [Components](#components)
* [Credits](#credits)
* [License](#license)


## Interface

### Swift

```swift
Sync.changes(
  changes: [AnyObject]!,
  inEntityNamed: String!,
  dataStack: DATAStack!,
  completion: ((NSError!) -> Void)!)
```

### Objective-C

```objc
+ (void)changes:(NSArray *)changes
  inEntityNamed:(NSString *)entityName
      dataStack:(DATAStack *)dataStack
     completion:(void (^)(NSError *error))completion
```

* `changes`: JSON response
* `entityName`: Core Data’s Model Entity Name (such as User, Note, Task)
* `dataStack`: Your [DATAStack](https://github.com/3lvis/DATAStack)


## Example

### Model

![Model](https://raw.githubusercontent.com/hyperoslo/Sync/master/Images/sync-model.png)

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

```objc
[Sync changes:JSON
inEntityNamed:@"User"
    dataStack:dataStack
   completion:^{
       // New objects have been inserted
       // Existing objects have been updated
       // And not found objects have been deleted
    }];
```

Alternatively if you only want to sync users that have been created in the last 24 hours, you could do this by using a `NSPredicate`.

```objc
NSDate *now = [NSDate date];
NSDate *yesterday = [now dateByAddingTimeInterval:-24*60*60];
NSPredicate *predicate = [NSPredicate predicateWithFormat:@"createdAt > %@", yesterday];

[Sync changes:JSON
inEntityNamed:@"User"
    predicate:predicate
    dataStack:dataStack
   completion:^{
       //...
    }];
```

### More Examples

<a href="https://github.com/hyperoslo/Sync/tree/master/Examples/AppNet/README.md">
  <img src="https://raw.githubusercontent.com/hyperoslo/Sync/master/Images/APPNET-v3.png" />
</a>

<a href="https://github.com/hyperoslo/Sync/tree/master/Examples/DesignerNews/README.md">
  <img src="https://raw.githubusercontent.com/hyperoslo/Sync/master/Images/DN-v4.png" />
</a>


## Getting Started

### Installation

**Sync** is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod 'Sync'
```

## Requisites

### Core Data Stack

Replace your Core Data stack with an instance of [DATAStack](https://github.com/3lvis/DATAStack).

```objc
self.dataStack = [[DATAStack alloc] initWithModelName:@"Demo"];
```

Then add this to your App Delegate so everything gets persisted when you quit the app.
```objc
- (void)applicationWillTerminate:(UIApplication *)application {
    [self.dataStack persistWithCompletion:nil];
}
```

### Primary key

Sync requires your entities to have a primary key, this is important for diffing otherwise Sync doesn’t know how to differentiate between entries.

By default **Sync** uses `id` from the JSON and `remoteID` from Core Data as the primary key. You can mark any attribute as primary key by adding `hyper.isPrimaryKey` and the value `YES`.

For example in our [Designer News](https://github.com/hyperoslo/Sync/tree/master/Examples/DesignerNews) project we have a `Comment` entity that uses `body` as the primary key.

![Custom primary key](https://raw.githubusercontent.com/hyperoslo/Sync/master/Images/custom-primary-key-v2.png)

### Attribute Mapping

Your attributes should match their JSON counterparts in `camelCase` notation instead of `snake_case`. For example `first_name` in the JSON maps to `firstName` in Core Data and `address` in the JSON maps to `address` in Core Data.

There are two exceptions to this rule:

* `id`s should match `remoteID`
* Reserved attributes should be prefixed with the `entityName` (`type` becomes `userType`, `description` becomes `userDescription` and so on). In the JSON they don't need to change, you can keep `type` and `description` for example. A full list of reserved attributes can be found [here](https://github.com/hyperoslo/NSManagedObject-HYPPropertyMapper/blob/master/Source/NSManagedObject%2BHYPPropertyMapper.m#L265)

If you want to map your Core Data attribute with a JSON attribute that has different naming, you can do by adding `hyper.remoteKey` in the user info box with the value you want to map.

![Custom remote key](https://raw.githubusercontent.com/hyperoslo/Sync/master/Images/custom-remote-key-v2.png)

### Attribute Types

#### Array/Dictionary

To map **arrays** or **dictionaries** just set attributes as `Binary Data` on the Core Data modeler.

![screen shot 2015-04-02 at 11 10 11 pm](https://cloud.githubusercontent.com/assets/1088217/6973785/7d3767dc-d98d-11e4-8add-9c9421b5ed47.png)

#### Retreiving mapped arrays
```json
{
  "hobbies": [
    "football",
    "soccer",
    "code"
  ]
}
```

```objc
NSArray *hobbies = [NSKeyedUnarchiver unarchiveObjectWithData:managedObject.hobbies];
// ==> "football", "soccer", "code" 
```

#### Retreiving mapped dictionaries
```json
{
  "expenses" : {
    "cake" : 12.50,
    "juice" : 0.50
  }
}
```

```objc
NSDictionary *expenses = [NSKeyedUnarchiver unarchiveObjectWithData:managedObject.expenses];
// ==> "cake" : 12.50, "juice" : 0.50
```

#### Dates

We went for just supporting [ISO8601](http://en.wikipedia.org/wiki/ISO_8601) out of the box because that's the most common format when parsing dates, also we have a [quite performant way to parse this strings](https://github.com/hyperoslo/NSManagedObject-HYPPropertyMapper/blob/master/Source/NSManagedObject%2BHYPPropertyMapper.m#L272-L319) which overcomes the [performance issues of using `NSDateFormatter`](http://blog.soff.es/how-to-drastically-improve-your-app-with-an-afternoon-and-instruments/).

```json
{
  "created_at": "2014-01-01T00:00:00+00:00",
  "updated_at": "2014-01-02",
  "number_of_attendes": 20
}
```

```objc
NSDate *createdAt = [managedObject valueForKey:@"createdAt"];
// ==> "2014-01-01 00:00:00 +00:00" 

NSDate *updatedAt = [managedObject valueForKey:@"updatedAt"];
// ==> "2014-01-02 00:00:00 +00:00" 
```

### Networking

You are free to use any networking library.

### Supported iOS Versions

`iOS 7 or above`


## Components

**Sync** wouldn’t be possible without the help of this *fully tested* components:

* [**DATAStack**](https://github.com/3lvis/DATAStack): Core Data stack and thread safe saving

* [**DATAFilter**](https://github.com/3lvis/DATAFilter): Helps you purge deleted objects, internally we use it to diff inserts, updates and deletes. Also it’s used for uniquing Core Data does this based on objectIDs, DATAFilter uses your remote keys (such as id) for this

* [**NSManagedObject-HYPPropertyMapper**](https://github.com/hyperoslo/NSManagedObject-HYPPropertyMapper): Maps JSON fields with their Core Data counterparts, it does most of it’s job using the paradigm “_convention over configuration_”


## Credits

[Hyper](http://hyper.no) made this. We’re a digital communications agency with a passion for good code and delightful user experiences. If you’re using this library we probably want to [hire you](https://github.com/hyperoslo/iOS-playbook/blob/master/HYPER_RECIPES.md) (we consider remote employees too, the only requirement is that you’re awesome).


## License

**Sync** is available under the MIT license. See the [LICENSE](https://github.com/hyperoslo/Sync/blob/master/LICENSE.md) file for more info.
