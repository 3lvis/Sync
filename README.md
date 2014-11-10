![Kipu](https://github.com/NSElvis/Kipu/blob/master/Images/logo.png)

[![CI Status](http://img.shields.io/travis/NSElvis/Kipu.svg?style=flat)](https://travis-ci.org/NSElvis/Kipu)
[![Version](https://img.shields.io/cocoapods/v/Kipu.svg?style=flat)](http://cocoadocs.org/docsets/Kipu)
[![License](https://img.shields.io/cocoapods/l/Kipu.svg?style=flat)](http://cocoadocs.org/docsets/Kipu)
[![Platform](https://img.shields.io/cocoapods/p/Kipu.svg?style=flat)](http://cocoadocs.org/docsets/Kipu)

>**quipu [*kee-poo*, *kwip-oo*]**: Sometimes called talking knots, were recording devices historically used in the region of Andean South America. A system also used for collecting data and keeping records, ranging from monitoring tax obligations, properly collecting census records, calendrical information, and military organization.

Kipu eases your every day job of parsing a `JSON` response and getting it into CoreData. It uses a convention over configuration paradigm to facilitate your workflow.

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

## Real World Example

#### Model

![Model](https://github.com/NSElvis/Kipu/blob/master/Images/coredata-model.png)

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

#### Kipu

```objc
[Kipu processChanges:JSON
     usingEntityName:@"User"
          completion:^{
              // Objects saved in CoreData, do something
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
