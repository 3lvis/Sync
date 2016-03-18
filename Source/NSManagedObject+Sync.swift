import CoreData
import NSEntityDescription_SYNCPrimaryKey
import DATAStack
import NSString_HYPNetworking

public extension NSManagedObject {
  /**
   Using objectID to fetch an NSManagedObject from a NSManagedContext is quite unsafe,
   and has unexpected behaviour most of the time, although it has gotten better throught
   the years, it's a simple method with not many moving parts.

   Copy in context gives you a similar behaviour, just a bit safer.
   - parameter context: The context where the NSManagedObject will be taken
   - returns: A NSManagedObject copied in the provided context.
   */
  func sync_copyInContext(context: NSManagedObjectContext) -> NSManagedObject {
    guard let entityName = entity.name, entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: context) else { abort() }

    return context.sync_safeObject(entityName, remoteID: valueForKey(entity.sync_localKey()), parent: nil, parentRelationshipName: nil)!
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
  func sync_fillWithDictionary(dictionary: [String : AnyObject], parent: NSManagedObject?, dataStack: DATAStack) {
    hyp_fillWithDictionary(dictionary)

    entity.sync_relationships().forEach { relationship in
      let constructedKeyName = relationship.name.hyp_remoteString() + "_id"
      let keyName = relationship.userInfo?[SYNCCustomRemoteKey] as? String ?? constructedKeyName

      if relationship.toMany {
        sync_toManyRelationship(relationship, dictionary: dictionary, parent: parent, dataStack: dataStack)
      } else if let parent = parent where !parent.isEqual(valueForKey(relationship.name)) && relationship.destinationEntity?.name == parent.entity.name {
        setValue(parent, forKey: relationship.name)
      } else if let remoteID = dictionary[keyName] where remoteID is NSString || remoteID is NSNumber {
        sync_relationshipUsingIDInsteadOfDictionary(relationship, remoteID: remoteID, dataStack: dataStack)
      } else {
        sync_toOneRelationship(relationship, dictionary: dictionary, dataStack: dataStack)
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
  func sync_toManyRelationship(relationship: NSRelationshipDescription, dictionary: [String : AnyObject], parent: NSManagedObject?, dataStack: DATAStack) {
    guard let managedObjectContext = managedObjectContext, destinationEntity = relationship.destinationEntity, childEntityName = destinationEntity.name else { abort() }

    let relationshipName = relationship.userInfo?[SYNCCustomRemoteKey] as? String ?? relationship.name.hyp_remoteString()
    let inverseIsToMany = relationship.inverseRelationship?.toMany ?? false

    if let children = dictionary[relationshipName] as? [[String : AnyObject]] {
      var childPredicate: NSPredicate?
      let childIDs = (children as NSArray).valueForKey(entity.sync_remoteKey())

      if let entity = NSEntityDescription.entityForName(childEntityName, inManagedObjectContext: managedObjectContext), childIDsObject = childIDs as? NSObject where inverseIsToMany && childIDs.count > 0 {
        childPredicate = NSPredicate(format: "ANY %K IN %@", entity.sync_localKey(), childIDsObject)
      } else if let inverseEntityName = relationship.inverseRelationship?.name {
        childPredicate = NSPredicate(format: "%K = %@", inverseEntityName, self)
      }

      Sync.changes(children, inEntityNamed: childEntityName, predicate: childPredicate, parent: self, inContext: managedObjectContext, dataStack: dataStack, completion: nil)
    } else if let parent = parent, entityName = parent.entity.name where inverseIsToMany && entityName == childEntityName {
      if relationship.ordered {
        let relatedObjects = mutableOrderedSetValueForKey(relationship.name)
        if !relatedObjects.containsObject(parent) {
          relatedObjects.addObject(parent)
          setValue(relatedObjects, forKey: relationship.name)
        }
      } else {
        let relatedObjects = mutableSetValueForKey(relationship.name)
        if !relatedObjects.containsObject(parent) {
          relatedObjects.addObject(parent)
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
   - parameter remoteID: The remoteID of the relationship to be synced.
   - parameter dataStack: The DATAStack instance.
   */
  func sync_relationshipUsingIDInsteadOfDictionary(relationship: NSRelationshipDescription, remoteID: AnyObject, dataStack: DATAStack) {
    guard let entityName = relationship.destinationEntity!.name, object = managedObjectContext!.sync_safeObject(entityName, remoteID: remoteID, parent: self, parentRelationshipName: relationship.name) else { abort() }

    let currentRelationship = valueForKey(relationship.name)
    if currentRelationship == nil || !currentRelationship!.isEqual(object) {
      setValue(object, forKey: relationship.name)
    }
  }

  /**
   Syncs the entity's to-one relationship, it will also sync the child of this entity.
   - parameter relationship: The relationship to be synced.
   - parameter dictionary: The JSON with the changes to be applied to the entity.
   - parameter dataStack: The DATAStack instance.
   */
  func sync_toOneRelationship(relationship: NSRelationshipDescription, dictionary: [String : AnyObject], dataStack: DATAStack) {
    let relationshipName = relationship.userInfo?[SYNCCustomRemoteKey] as? String ?? relationship.name.hyp_remoteString()

    guard let managedObjectContext = managedObjectContext, filteredObjectDictionary = dictionary[relationshipName] as? [String : AnyObject], destinationEntity = relationship.destinationEntity, entityName = destinationEntity.name, entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: managedObjectContext) else { return }

    let remoteID = filteredObjectDictionary[entity.sync_remoteKey()]
    let object = managedObjectContext.sync_safeObject(entityName, remoteID: remoteID, parent: self, parentRelationshipName: relationship.name) ?? NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: managedObjectContext)

    object.sync_fillWithDictionary(filteredObjectDictionary, parent: self, dataStack: dataStack)

    let currentRelationship = valueForKey(relationship.name)
    if currentRelationship == nil || !currentRelationship!.isEqual(object) {
      setValue(object, forKey: relationship.name)
    }
  }
}
