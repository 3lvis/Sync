![Kipu](https://github.com/NSElvis/Kipu/blob/test-logo/Images/logo.png)

[![CI Status](http://img.shields.io/travis/NSElvis/Kipu.svg?style=flat)](https://travis-ci.org/NSElvis/Kipu)
[![Version](https://img.shields.io/cocoapods/v/Kipu.svg?style=flat)](http://cocoadocs.org/docsets/Kipu)
[![License](https://img.shields.io/cocoapods/l/Kipu.svg?style=flat)](http://cocoadocs.org/docsets/Kipu)
[![Platform](https://img.shields.io/cocoapods/p/Kipu.svg?style=flat)](http://cocoadocs.org/docsets/Kipu)

Kipu eases your every day job of parsing a `JSON` response and getting it into CoreData.

* Handles operations in safe background threats
* Thread safe saving, we handle retrieving and storing objects in the right threads
* Diffing of changes, updated, inserted and deleted objects (which are automatically purged for you)
* Auto-mapping of relationships (one-to-one, one-to-many and many-to-many)
* Smart-updates, only updates your NSManagedObjects if the server values are different (useful when using NSFetchedResultsController delegates)

## Interface

```objc
+ (void)processChanges:(NSArray *)changes
       usingEntityName:(NSString *)entityName
            completion:(void (^)(NSError *error))completion
```

* `changes`: JSON response
* `entityName`: Core Data's Model Entity Name (such as User, Note, Task)

*Take a look at the [wiki](https://github.com/NSElvis/Kipu/wiki) for additional configurations and more info about the possibilities*

## Real World Example

#### Model

![Model](https://github.com/NSElvis/Kipu/blob/master/Images/model.png)

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

#### Kipu

```objc
[Kipu processChanges:JSON
      usingEntityName:@"User"
           completion:^{
               // stop progress hud?
            }];
```
**PROFIT!**

## Requirements

`iOS 7`, `CoreData`, [`ANDYDataManager CoreData stack`](https://github.com/NSElvis/ANDYDataManager) *(optional)*

## Installation

**Kipu** is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

`pod 'Kipu'`

## Components

**Kipu** wouldn't be possible without the help of this *fully tested* components:

* [ANDYDataManager](https://github.com/NSElvis/ANDYDataManager)
* [NSManagedObject+ANDYMapChanges](https://github.com/NSElvis/NSManagedObject-ANDYMapChanges)
* [NSManagedObject+HYPPropertyMapper](https://github.com/hyperoslo/NSManagedObject-HYPPropertyMapper)

## Author

Elvis Nuñez, [hello@nselvis.com](mailto:hello@nselvis.com)

## License

**Kipu** is available under the MIT license. See the [LICENSE](https://github.com/NSElvis/Kipu/blob/master/LICENSE.md) file for more info.
