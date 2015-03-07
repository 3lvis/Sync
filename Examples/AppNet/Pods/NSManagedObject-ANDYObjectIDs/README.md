# NSManagedObject-ANDYObjectIDs

[![CI Status](http://img.shields.io/travis/NSElvis/NSManagedObject-ANDYObjectIDs.svg?style=flat)](https://travis-ci.org/NSElvis/NSManagedObject-ANDYObjectIDs)
[![Version](https://img.shields.io/cocoapods/v/NSManagedObject-ANDYObjectIDs.svg?style=flat)](http://cocoadocs.org/docsets/NSManagedObject-ANDYObjectIDs)
[![License](https://img.shields.io/cocoapods/l/NSManagedObject-ANDYObjectIDs.svg?style=flat)](http://cocoadocs.org/docsets/NSManagedObject-ANDYObjectIDs)
[![Platform](https://img.shields.io/cocoapods/p/NSManagedObject-ANDYObjectIDs.svg?style=flat)](http://cocoadocs.org/docsets/NSManagedObject-ANDYObjectIDs)

## Usage

```objc
NSDictionary *dictionary = [NSManagedObject andy_dictionaryOfIDsAndFetchedIDsInContext:self.managedObjectContext
                                                                         usingLocalKey:@"remoteID"
                                                                         forEntityName:@"User"];
```

This will be a dictionary that has as keys your primary key, such as the `remoteID`, and as value the `NSManagedObjectID`.

## Installation

**NSManagedObject-ANDYObjectIDs** is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'NSManagedObject-ANDYObjectIDs'
```

## Author

Elvis Nuñez, hello@nselvis.com

## License

**NSManagedObject-ANDYObjectIDs** is available under the MIT license. See the LICENSE file for more info.
