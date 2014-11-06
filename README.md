# NSManagedObject-ANDYNetworking

[![CI Status](http://img.shields.io/travis/NSElvis/NSManagedObject-ANDYNetworking.svg?style=flat)](https://travis-ci.org/NSElvis/NSManagedObject-ANDYNetworking)
[![Version](https://img.shields.io/cocoapods/v/NSManagedObject-ANDYNetworking.svg?style=flat)](http://cocoadocs.org/docsets/NSManagedObject-ANDYNetworking)
[![License](https://img.shields.io/cocoapods/l/NSManagedObject-ANDYNetworking.svg?style=flat)](http://cocoadocs.org/docsets/NSManagedObject-ANDYNetworking)
[![Platform](https://img.shields.io/cocoapods/p/NSManagedObject-ANDYNetworking.svg?style=flat)](http://cocoadocs.org/docsets/NSManagedObject-ANDYNetworking)

This is a category that eases your every day job of parsing a `JSON` response and getting it into CoreData.

* Handles operations in safe background threats
* Thread safe saving, we handle retrieving and storing objects in the right threads
* Diffing of changes, updated, inserted and deleted objects (which are automatically purged for you)
* Auto-mapping of relationships (one-to-one, one-to-many and many-to-many)
* Completion block returns in the main thread, in case you want to update your UI
* Smart-updates, only updates your NSManagedObjects if the server values are different (useful when using NSFetchedResultsController delegates)

## Interface

```objc
+ (void)andy_processChanges:(NSArray *)changes
            usingEntityName:(NSString *)entityName
                 completion:(void (^)(NSError *error))completion
```

* `changes`: JSON response
* `entityName`: Core Data's Model Entity Name (such as User, Note, Task)

*Take a look at the [wiki](https://github.com/NSElvis/NSManagedObject-ANDYNetworking/wiki) for additional configurations and more info about the possibilities*

## Real World Example

#### Model

![Model](https://github.com/NSElvis/NSManagedObject-ANDYNetworking/blob/master/Images/model.png)

#### JSON

```json
[
  {
    "id": 6,
    "name": "Shawn Merrill",
    "email": "shawn@ovium.com",
    "notes": [
      {
        "id": 0,
        "text": "Shawn Merril's diary, episode 1"
      }
    ]
  }
]
```

#### NSManagedObject-ANDYNetworking

```objc
[NSManagedObject andy_processChanges:JSON
                     usingEntityName:@"User"
                          completion:^{
                              // stop progress hud?
                          }];
```
**PROFIT!**

## Requirements

`iOS 7`, `CoreData`, [`ANDYDataManager CoreData stack`](https://github.com/NSElvis/ANDYDataManager) *(optional)*

## Installation

**NSManagedObject-ANDYNetworking** is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

`pod 'NSManagedObject-ANDYNetworking'`

## Components

**NSManagedObject-ANDYNetworking** wouldn't be possible without the help of this *fully tested* components:

* [ANDYDataManager](https://github.com/NSElvis/ANDYDataManager)
* [NSManagedObject+ANDYMapChanges](https://github.com/NSElvis/NSManagedObject-ANDYMapChanges)
* [NSManagedObject+HYPPropertyMapper](https://github.com/hyperoslo/NSManagedObject-HYPPropertyMapper)

## Author

Elvis Nuñez, [hello@nselvis.com](mailto:hello@nselvis.com)

## License

**NSManagedObject-ANDYNetworking** is available under the MIT license. See the [LICENSE](https://github.com/NSElvis/NSManagedObject-ANDYNetworking/blob/master/LICENSE.md) file for more info.

