# NSString-HYPNetworking

[![CI Status](http://img.shields.io/travis/hyperoslo/NSString-HYPNetworking.svg?style=flat)](https://travis-ci.org/hyperoslo/NSString-HYPNetworking)
[![Version](https://img.shields.io/cocoapods/v/NSString-HYPNetworking.svg?style=flat)](http://cocoadocs.org/docsets/NSString-HYPNetworking)
[![License](https://img.shields.io/cocoapods/l/NSString-HYPNetworking.svg?style=flat)](http://cocoadocs.org/docsets/NSString-HYPNetworking)
[![Platform](https://img.shields.io/cocoapods/p/NSString-HYPNetworking.svg?style=flat)](http://cocoadocs.org/docsets/NSString-HYPNetworking)

## Usage

### Basic

```objc
[@"driverIdentifier" hyp_remoteString];

// => driver_identifier
```

```objc
[@"driver_identifier" hyp_localString];

// => driverIdentifier
```

### Acronyms

It supports `id`, `pdf`, `url`, `png`, `jpg`.

```objc
[@"userID" hyp_remoteString];

// => user_id
```

```objc
[@"user_id" hyp_localString];

// => userID
```

### Dates

It supports `created_at`, `updated_at`.

```objc
[@"createdDate" hyp_remoteString];

// => created_at
```

```objc
[@"created_at" hyp_localString];

// => createdDate
```

## Installation

**NSString-HYPNetworking** is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

`pod 'NSString-HYPNetworking'`

## Author

Hyper AS, teknologi@hyper.no

## License

**NSString-HYPNetworking** is available under the MIT license. See the LICENSE file for more info.
