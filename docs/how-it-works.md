# How It Works

Sync uses your Core Data model to infer how it will do the mapping and diffing. How the sync proccess works could be split in three parts:

- Diffing
- Relationship mapping
- Attribute mapping

### Diffing

The diffing part is the first thing is done in Sync, it separates inserted, updated and deleted items in three collections. This process is done by the [DataFilter](https://github.com/SyncDB/Sync/blob/master/Source/DataFilter/DataFilter.swift). To be able to diff our entries Sync requires a primary key and a collection of remote items for comparison. If there's a local entry with the same primary key as one from the remote collection this item will go to the updated collection, if there's a remote primary key that is not found in the database then the item will go to the inserted collection, finally, if there's an item in the database that is not found in the remote collection, then this item will go to the deleted collection. At the end of this process inserted and updated items will go back to Sync where the mapping will be done, and the items in the deleted collection will be removed from the database.

A lot of times the remote collection doesn't represent all the entries in the database for a specific entity, for example, you might have in your remote collection all the articles posted in the last day, meanwhile in your database you have all the entries posted ever. To ensure that the diffing only happens with the entries in the database that were posted in the last day Sync uses a predicate, this predicate will filter out the entries in the database that will be used for comparison.

### Relationship mapping

After going through the diffing process Sync will iterate through each entry if it's an insertion it will make a new entry in the database and fill the contents of this entry with the JSON ignoring relationships. If it's an updated entry then it will just fill the attributes.

This is the method call that we would be using for the following examples:

```swift
Sync.changes(json, inEntityNamed: "Users", dataStack: dataStack) { error in
    // Completed...
}
```

#### One-to-one

One-to-one relationships have have the following structure:

```json
[
  {
    "id": 1,
    "name": "John Appleseed",
    "company": {
      "id": 12,
      "name": "Apple"
    }
  }
]
```

Here Sync will check that in your Core Data model for the User entity there's a `to-one` relationship with the Company entity. Then it will verify that there also exists a dictionary named "company" in the JSON. After doing this  then Sync will confirm that this is indeed a `to-one` relationship mapping. After, Sync will look for an existing entry in the Company table for the primary key `12`, if there's one, it will use that to link it to the user, otherwise it will make a new Company entry and link that instead, finally it will fill all the attributes of the company with the contents of the company JSON.

#### One-to-many

```json
[
  {
    "id": 1,
    "name": "John Appleseed",
    "notes": [
      {
        "id": 12,
        "text": "List of things to remember"
      }
    ]
  }
]
```

#### Many-to-many

```json
[
  {
    "id": 1,
    "name": "John Appleseed",
    "projects": [
      {
        "id": 12,
        "name": "To-do list"
      }
    ]
  }
]
```
