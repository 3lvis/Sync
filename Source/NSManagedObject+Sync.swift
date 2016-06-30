import CoreData
import NSEntityDescription_SYNCPrimaryKey
import DATAStack
import NSString_HYPNetworking
import DATAFilter

public extension NSManagedObject {
  /**
   Using objectID to fetch an NSManagedObject from a NSManagedContext is quite unsafe,
   and has unexpected behaviour most of the time, although it has gotten better throught
   the years, it's a simple method with not many moving parts.

   Copy in context gives you a similar behaviour, just a bit safer.
   - parameter context: The context where the NSManagedObject will be taken
   - returns: A NSManagedObject copied in the provided context.
   */
  func sync_copyInContext(_ context: NSManagedObjectContext) -> NSManagedObject {
    guard let entityName = entity.name, entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else { abort() }
    let localPrimaryKey = value(forKey: entity.sync_localPrimaryKey())
    guard let copiedObject = context.sync_safeObject(entityName, localPrimaryKey: localPrimaryKey, parent: nil, parentRelationshipName: nil) else { fatalError("Couldn't fetch a safe object from entityName: \(entityName) localPrimaryKey: \(localPrimaryKey)") }

    return copiedObject
  }

  /**
   Syncs the entity using the received dictionary, maps one-to-many, many-to-many and one-to-one relationships.
   It also syncs relationships where only the id is present, for example if your model is: Company -> Employee,
   and your employee has a company_id, it will try to sync using that ID instead of requiring you to provide the
   entire company object inside the employees dictionary.
   - parameter dictionary: The JSON with the changes to be applied to the entity.
   - parameter parent: The parent of the entity, optional since many entities are orphans.
   - parameter dataStack: The DATAStack instance.
   */
  func sync_fillWithDictionary(_ dictionary: [String : AnyObject], parent: NSManagedObject?, dataStack: DATAStack, operations: DATAFilterOperation) {
    hyp_fill(with: dictionary)

    entity.sync_relationships().forEach { relationship in
      let suffix = relationship.isToMany ? "_ids" : "_id"
      let constructedKeyName = relationship.name.hyp_remote() + suffix
      let keyName = relationship.userInfo?[SYNCCustomRemoteKey] as? String ?? constructedKeyName

      if relationship.isToMany {
        if let localPrimaryKey = dictionary[keyName] where localPrimaryKey is Array<String> || localPrimaryKey is Array<Int> || localPrimaryKey is NSNull {
          sync_toManyRelationshipUsingIDsInsteadOfDictionary(relationship, localPrimaryKey: localPrimaryKey)
        } else {
          sync_toManyRelationship(relationship, dictionary: dictionary, parent: parent, dataStack: dataStack, operations: operations)
        }
      } else if let parent = parent where !parent.isEqual(value(forKey: relationship.name)) && relationship.destinationEntity?.name == parent.entity.name {
        setValue(parent, forKey: relationship.name)
      } else if let localPrimaryKey = dictionary[keyName] where localPrimaryKey is NSString || localPrimaryKey is NSNumber || localPrimaryKey is NSNull {
        sync_toOneRelationshipUsingIDInsteadOfDictionary(relationship, localPrimaryKey: localPrimaryKey, dataStack: dataStack)
      } else {
        sync_toOneRelationship(relationship, dictionary: dictionary, dataStack: dataStack, operations: operations)
      }
    }
  }

  /**
   Syncs relationships where only the ids are present, for example if your model is: User <<->> Tags (a user has many tags and a tag belongs to many users),
   and your tag has a users_ids, it will try to sync using those ID instead of requiring you to provide the entire users list inside each tag.
   - parameter relationship: The relationship to be synced.
   - parameter localPrimaryKey: The localPrimaryKey of the relationship to be synced, usually an array of strings or numbers.
   */
  func sync_toManyRelationshipUsingIDsInsteadOfDictionary(_ relationship: NSRelationshipDescription, localPrimaryKey: AnyObject) {
    guard let managedObjectContext = managedObjectContext else { fatalError("managedObjectContext not found") }
    guard let destinationEntity = relationship.destinationEntity else { fatalError("destinationEntity not found in relationship: \(relationship)") }
    guard let destinationEntityName = destinationEntity.name else { fatalError("entityName not found in entity: \(destinationEntity)") }
    guard let entity = NSEntityDescription.entity(forEntityName: destinationEntityName, in: managedObjectContext) else { return }
    if localPrimaryKey is NSNull {
      if let _ = value(forKey: relationship.name) {
        setValue(nil, forKey: relationship.name)
      }
    } else {
      guard let localPrimaryKey = localPrimaryKey as? NSArray else { return }
      let remoteItems = localPrimaryKey
      let localRelationship: NSSet
      if relationship.isOrdered {
        let value = self.value(forKey: relationship.name) as? OrderedSet ?? OrderedSet()
        localRelationship = value.set
      } else {
        localRelationship = self.value(forKey: relationship.name) as? NSSet ?? NSSet()
      }
      let localItems = localRelationship.value(forKey: entity.sync_localPrimaryKey()) as? NSSet ?? NSSet()

      let deletedItems = NSMutableArray(array: localItems.allObjects)
      deletedItems.removeObjects(in: remoteItems as [AnyObject])

      let insertedItems = remoteItems.mutableCopy() as? NSMutableArray ?? NSMutableArray()
      insertedItems.removeObjects(in: localItems.allObjects)

      guard insertedItems.count > 0 || deletedItems.count > 0 else { return }
      let request = NSFetchRequest<NSFetchRequestResult>(entityName: destinationEntityName)
      let fetchedObjects = try? managedObjectContext.fetch(request) as? [NSManagedObject] ?? [NSManagedObject]()
      guard let objects = fetchedObjects else { return }
      for safeObject in objects {
        let currentID = safeObject.value(forKey: entity.sync_localPrimaryKey())!
        for inserted in insertedItems {
          if currentID.isEqual(inserted) {
            if relationship.isOrdered {
              let relatedObjects = mutableOrderedSetValue(forKey: relationship.name)
              if !relatedObjects.contains(safeObject) {
                relatedObjects.add(safeObject)
                setValue(relatedObjects, forKey: relationship.name)
              }
            } else {
              let relatedObjects = mutableSetValue(forKey: relationship.name)
              if !relatedObjects.contains(safeObject) {
                relatedObjects.add(safeObject)
                setValue(relatedObjects, forKey: relationship.name)
              }
            }
          }
        }

        for deleted in deletedItems {
          if currentID.isEqual(deleted) {
            if relationship.isOrdered {
              let relatedObjects = mutableOrderedSetValue(forKey: relationship.name)
              if relatedObjects.contains(safeObject) {
                relatedObjects.remove(safeObject)
                setValue(relatedObjects, forKey: relationship.name)
              }
            } else {
              let relatedObjects = mutableSetValue(forKey: relationship.name)
              if relatedObjects.contains(safeObject) {
                relatedObjects.remove(safeObject)
                setValue(relatedObjects, forKey: relationship.name)
              }
            }
          }
        }
      }
    }
  }

  /**
   Syncs the entity's to-many relationship, it will also sync the childs of this relationship.
   - parameter relationship: The relationship to be synced.
   - parameter dictionary: The JSON with the changes to be applied to the entity.
   - parameter parent: The parent of the entity, optional since many entities are orphans.
   - parameter dataStack: The DATAStack instance.
   */
  func sync_toManyRelationship(_ relationship: NSRelationshipDescription, dictionary: [String : AnyObject], parent: NSManagedObject?, dataStack: DATAStack, operations: DATAFilterOperation) {
    guard let managedObjectContext = managedObjectContext, destinationEntity = relationship.destinationEntity, childEntityName = destinationEntity.name else { abort() }

    let relationshipName = relationship.userInfo?[SYNCCustomRemoteKey] as? String ?? relationship.name.hyp_remote()
    let inverseIsToMany = relationship.inverseRelationship?.isToMany ?? false

    if let children = dictionary[relationshipName] as? [[String : AnyObject]] {
      var childPredicate: Predicate?
      let childIDs = (children as NSArray).value(forKey: entity.sync_remotePrimaryKey())

      let manyToMany = inverseIsToMany && relationship.isToMany
      if manyToMany {
        if childIDs.count > 0 {
          guard let entity = NSEntityDescription.entity(forEntityName: childEntityName, in: managedObjectContext) else { fatalError() }
          guard let childIDsObject = childIDs as? NSObject else { fatalError() }
          childPredicate = Predicate(format: "ANY %K IN %@", entity.sync_localPrimaryKey(), childIDsObject)
        }
      } else {
        guard let inverseEntityName = relationship.inverseRelationship?.name else { fatalError() }
        childPredicate = Predicate(format: "%K = %@", inverseEntityName, self)
      }

      Sync.changes(children, inEntityNamed: childEntityName, predicate: childPredicate, parent: self, inContext: managedObjectContext, dataStack: dataStack, operations: operations, completion: nil)
    } else if let parent = parent, entityName = parent.entity.name where inverseIsToMany && entityName == childEntityName {
      if relationship.isOrdered {
        let relatedObjects = mutableOrderedSetValue(forKey: relationship.name)
        if !relatedObjects.contains(parent) {
          relatedObjects.add(parent)
          setValue(relatedObjects, forKey: relationship.name)
        }
      } else {
        let relatedObjects = mutableSetValue(forKey: relationship.name)
        if !relatedObjects.contains(parent) {
          relatedObjects.add(parent)
          setValue(relatedObjects, forKey: relationship.name)
        }
      }
    }
  }

  /**
   Syncs relationships where only the id is present, for example if your model is: Company -> Employee,
   and your employee has a company_id, it will try to sync using that ID instead of requiring you to provide the
   entire company object inside the employees dictionary.
   - parameter relationship: The relationship to be synced.
   - parameter localPrimaryKey: The localPrimaryKey of the relationship to be synced, usually a number or an integer.
   - parameter dataStack: The DATAStack instance.
   */
  func sync_toOneRelationshipUsingIDInsteadOfDictionary(_ relationship: NSRelationshipDescription, localPrimaryKey: AnyObject, dataStack: DATAStack) {
    guard let managedObjectContext = managedObjectContext else { fatalError("managedObjectContext not found") }
    guard let destinationEntity = relationship.destinationEntity else { fatalError("destinationEntity not found in relationship: \(relationship)") }
    guard let destinationEntityName = destinationEntity.name else { fatalError("entityName not found in entity: \(destinationEntity)") }
    if localPrimaryKey is NSNull {
      if let _ = value(forKey: relationship.name) {
        setValue(nil, forKey: relationship.name)
      }
    } else if let safeObject = managedObjectContext.sync_safeObject(destinationEntityName, localPrimaryKey: localPrimaryKey, parent: self, parentRelationshipName: relationship.name) {
      let currentRelationship = value(forKey: relationship.name)
      if currentRelationship == nil || !currentRelationship!.isEqual(safeObject) {
        setValue(safeObject, forKey: relationship.name)
      }
    } else {
      print("Trying to sync a \(self.entity.name!) \(self) with a \(destinationEntityName) with ID \(localPrimaryKey), didn't work because \(destinationEntityName) doesn't exist. Make sure the \(destinationEntityName) exists before proceeding.")
    }
  }

  /**
   Syncs the entity's to-one relationship, it will also sync the child of this entity.
   - parameter relationship: The relationship to be synced.
   - parameter dictionary: The JSON with the changes to be applied to the entity.
   - parameter dataStack: The DATAStack instance.
   */
  func sync_toOneRelationship(_ relationship: NSRelationshipDescription, dictionary: [String : AnyObject], dataStack: DATAStack, operations: DATAFilterOperation) {
    let relationshipName = relationship.userInfo?[SYNCCustomRemoteKey] as? String ?? relationship.name.hyp_remote()

    guard let managedObjectContext = managedObjectContext, filteredObjectDictionary = dictionary[relationshipName] as? [String : AnyObject], destinationEntity = relationship.destinationEntity, entityName = destinationEntity.name, entity = NSEntityDescription.entity(forEntityName: entityName, in: managedObjectContext) else { return }

    let localPrimaryKey = filteredObjectDictionary[entity.sync_remotePrimaryKey()]
    let object = managedObjectContext.sync_safeObject(entityName, localPrimaryKey: localPrimaryKey, parent: self, parentRelationshipName: relationship.name) ?? NSEntityDescription.insertNewObject(forEntityName: entityName, into: managedObjectContext)

    object.sync_fillWithDictionary(filteredObjectDictionary, parent: self, dataStack: dataStack, operations: operations)

    let currentRelationship = value(forKey: relationship.name)
    if currentRelationship == nil || !currentRelationship!.isEqual(object) {
      setValue(object, forKey: relationship.name)
    }
  }
}
