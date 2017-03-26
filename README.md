![Sync](https://raw.githubusercontent.com/SyncDB/Sync/master/Images/logo-v3.png)

<div align = "center">
  <a href="https://cocoapods.org/pods/Sync">
    <img src="https://img.shields.io/cocoapods/v/Sync.svg?style=flat" />
  </a>
  <a href="https://github.com/SyncDB/Sync">
    <img src="https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat" />
  </a>
  <a href="https://github.com/SyncDB/Sync#installation">
    <img src="https://img.shields.io/badge/compatible-swift%203.0-orange.svg" />
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
* Thread-safe saving, we handle retrieving and storing objects in the right threads
* Diffing of changes, updated, inserted and deleted objects (which are automatically purged for you)
* Auto-mapping of relationships (one-to-one, one-to-many and many-to-many)
* Smart-updates, only updates your `NSManagedObject`s if the server values are different from your local ones
* Uniquing, one Core Data entry per primary key
* `NSOperation` subclass, any Sync process can be queued and cancelled at any time!

## Table of Contents

* [Simple example](#simple-example)
* [Installation](#installation)
* [Credits](#credits)
* [License](#license)

## Simple example

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

**Sync** of course does much more than this, it supports a lot of customization and mapping between one-to-one, one-to-many, many-to-many, also mapping JSONs where you only reference the ID instead of the full object of your relationship. Check out the docs for more.

## Installation

### CocoaPods

#### Swift
```ruby
pod 'Sync', '~> 3'
```

### Carthage

```ruby
github "SyncDB/Sync" ~> 3.0
```

### Supported iOS, OS X, watchOS and tvOS Versions

- iOS 9 or above
- OS X 10.11 or above
- watchOS 2.0 or above
- tvOS 9.0 or above

## License

**Sync** is available under the MIT license. See the [LICENSE](https://github.com/SyncDB/Sync/blob/master/LICENSE.md) file for more info.
