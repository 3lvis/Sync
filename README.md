![Hyper Sync™](https://github.com/hyperoslo/Sync/blob/master/Images/logo.png)

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
+ (void)processChanges:(NSArray *)changes
       usingEntityName:(NSString *)entityName
             dataStack:(DATAStack *)dataStack
            completion:(void (^)(NSError *error))completion
```

* `changes`: JSON response
* `entityName`: Core Data's Model Entity Name (such as User, Note, Task)
* `dataStack`: Your [DATAStack](https://github.com/NSElvis/DATAStack)

## Real World Example

#### Model

![Model](https://github.com/hyperoslo/Sync/blob/master/Images/coredata-model.png)

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
[Sync processChanges:JSON
     usingEntityName:@"User"
           dataStack:dataStack
          completion:^{
              // Objects saved in Core Data, do something
           }];
```

[(You can see another example here).](https://github.com/hyperoslo/Sync/blob/master/Example/Example/ViewController.m#L94)

**PROFIT!**

## Getting Started

### Installation

**Sync** is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod 'Sync'
```

### DATAStack

Replace your Core Data stack with [an instance of DATAStack](https://github.com/NSElvis/DATAStack/blob/master/Demo/Demo/AppDelegate/ANDYAppDelegate.m#L19):

```objc
- (void)applicationWillTerminate:(UIApplication *)application
{
    [self.dataStack persistWithCompletion:nil];
}
```

### NSManagedObject-HYPPropertyMapper

Your Core Data entities should match your backend models. Your attributes should match their JSON counterparts. For example `first_name` maps to `firstName`, `address` to `address`.

There are only two exceptions to this rule:

* `id`s should match `remoteID`
* `created_at` and `updated_at` should match `createdDate` and `updatedDate`

### Networking

You are free to use any networking library or NSURLConnection.

### Finally

You are ready to go, check the [example project that uses App.net](https://github.com/hyperoslo/Sync/tree/master/Example) for how to use Sync.

## Requirements

`iOS 7 or above`, [`DATAStack Core Data stack`](https://github.com/NSElvis/DATAStack)

## Components

**Sync** wouldn't be possible without the help of this *fully tested* components:

* [**DATAStack**](https://github.com/NSElvis/DATAStack): Core Data stack and thread safe saving

* [**NSManagedObject-ANDYMapChanges**](https://github.com/NSElvis/NSManagedObject-ANDYMapChanges): Helps you purge deleted objects, internally we use it to diff inserts, updates and deletes. Also it's used for uniquing Core Data does this based on objectIDs, ANDYMapChanges uses your remote keys (such as id) for this

* [**NSManagedObject-HYPPropertyMapper**](https://github.com/hyperoslo/NSManagedObject-HYPPropertyMapper): Maps JSON fields with their Core Data counterparts, it does most of it's job using the paradigm "_convention over configuration_"

## Author

Hyper AS, [iOS@hyper.no](mailto:iOS@hyper.no)

## License

**Sync** is available under the MIT license. See the [LICENSE](https://github.com/hyperoslo/Sync/blob/master/LICENSE.md) file for more info.
