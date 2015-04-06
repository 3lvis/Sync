![Hyper Sync™](https://github.com/hyperoslo/Sync/blob/master/Images/logo-v2.png)

[![CI Status](http://img.shields.io/travis/hyperoslo/Sync.svg?style=flat)](https://travis-ci.org/hyperoslo/Sync)
[![Version](https://img.shields.io/cocoapods/v/Sync.svg?style=flat)](http://cocoadocs.org/docsets/Sync)
[![License](https://img.shields.io/cocoapods/l/Sync.svg?style=flat)](http://cocoadocs.org/docsets/Sync)
[![Platform](https://img.shields.io/cocoapods/p/Sync.svg?style=flat)](http://cocoadocs.org/docsets/Sync)

Sync eases your every day job of parsing a `JSON` response and getting it into Core Data. It uses a convention over configuration paradigm to facilitate your workflow.

* Handles operations in safe background threads
* Thread safe saving, we handle retrieving and storing objects in the right threads
* Diffing of changes, updated, inserted and deleted objects (which are automatically purged for you)
* Auto-mapping of relationships (one-to-one, one-to-many and many-to-many)
* Smart-updates, only updates your `NSManagedObject`s if the server values are different (useful when using `NSFetchedResultsController` delegates)
* Uniquing, Core Data does this based on `objectID`s, we use your remote key (such as `id`) for this

## Interface

```objc
+ (void)changes:(NSArray *)changes
  inEntityNamed:(NSString *)entityName
      dataStack:(DATAStack *)dataStack
     completion:(void (^)(NSError *error))completion
```

* `changes`: JSON response
* `entityName`: Core Data's Model Entity Name (such as User, Note, Task)
* `dataStack`: Your [DATAStack](https://github.com/3lvis/DATAStack)

## Example

#### Model

![Model](https://raw.githubusercontent.com/hyperoslo/Sync/master/Images/coredata-model-v4.png)

#### JSON

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

#### Sync

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

## Getting Started

### Installation

**Sync** is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod 'Sync'
```

## Requisites

### DATAStack

Replace your Core Data stack with [an instance of DATAStack](https://github.com/3lvis/DATAStack/blob/master/Demo/Demo/AppDelegate/ANDYAppDelegate.m#L19):

```objc
- (void)applicationWillTerminate:(UIApplication *)application
{
    [self.dataStack persistWithCompletion:nil];
}
```

### NSManagedObject-HYPPropertyMapper

Your Core Data entities should match your backend models. Your attributes should match their JSON counterparts. For example `first_name` maps to `firstName`, `address` to `address`.

There's two exceptions to this rule:

* `id`s should match `remoteID`
* Reserved attributes should be prefixed with the `entityName` (`type` becomes `userType`, `description` becomes `userDescription` and so on). In the JSON they don't need to change, you can keep `type` and `description` for example. A full list of reserved attributes can be found [here](https://github.com/hyperoslo/NSManagedObject-HYPPropertyMapper/blob/master/Source/NSManagedObject%2BHYPPropertyMapper.m#L265)

### Networking

You are free to use any networking library.

### Supported iOS version

`iOS 7 or above`

## Components

**Sync** wouldn't be possible without the help of this *fully tested* components:

* [**DATAStack**](https://github.com/3lvis/DATAStack): Core Data stack and thread safe saving

* [**DATAFilter**](https://github.com/3lvis/DATAFilter): Helps you purge deleted objects, internally we use it to diff inserts, updates and deletes. Also it's used for uniquing Core Data does this based on objectIDs, DATAFilter uses your remote keys (such as id) for this

* [**NSManagedObject-HYPPropertyMapper**](https://github.com/hyperoslo/NSManagedObject-HYPPropertyMapper): Maps JSON fields with their Core Data counterparts, it does most of it's job using the paradigm "_convention over configuration_"

## Author

Hyper AS, [iOS@hyper.no](mailto:iOS@hyper.no)

## License

**Sync** is available under the MIT license. See the [LICENSE](https://github.com/hyperoslo/Sync/blob/master/LICENSE.md) file for more info.
