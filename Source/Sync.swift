import UIKit
import CoreData

let CustomPrimaryKey = "hyper.isPrimaryKey"
let CustomRemoteKey = "hyper.remoteKey"
let DefaultLocalPrimaryKey = "remoteID"
let DefaultRemotePrimaryKey = "id"

private extension NSEntityDescription {

  func sync_localKey() -> String {
    var localKey = DefaultLocalPrimaryKey

    for (key, attributedDescription) in self.propertiesByName {
      if let
        userInfo: Dictionary = attributedDescription.userInfo,
        customPrimaryKey = userInfo[CustomPrimaryKey] as? String
        where customPrimaryKey == "YES" {
          localKey = key as! String
      }
    }

    return localKey
  }

  func sync_remoteKey() -> String {
    var remoteKey = DefaultRemotePrimaryKey
    let localKey = sync_localKey()

    if localKey != DefaultLocalPrimaryKey {
      remoteKey = localKey.hyp_remoteString()
    }

    return remoteKey
  }

}

extension NSManagedObject {

  public func sync_processRelationshipsUsingDictionary(objectDictionary dictionary: [NSObject : AnyObject],
    parent: NSManagedObject?,
    dataStack: DATAStack!) {
      let relationships = self.sync_relationships()

      for relationship in relationships {
        if relationship.toMany {
          self.sync_processToManyRelationship(relationship,
            usingDictionary: dictionary,
            parent: parent,
            dataStack: dataStack)
        } else if parent != nil && relationship.destinationEntity?.name == parent?.entity.name! {
          self.setValue(parent!, forKey: relationship.name)
        } else {
          self.sync_processToOneRelationship(relationship,
            usingDictionary: dictionary)
        }
      }
  }

  private func relationshipName(relationship: NSRelationshipDescription) -> String {
    var relationshipName = relationship.name

    if let
      userInfo = relationship.userInfo,
      relationshipKey = userInfo[CustomRemoteKey] as? String {
        relationshipName = relationshipKey
    }

    return relationshipName
  }

  private func sync_copyInContext(context: NSManagedObjectContext) -> NSManagedObject? {
    let entity = NSEntityDescription.entityForName(self.entity.name!,
      inManagedObjectContext: context)

    let localKey = entity!.sync_localKey()
    let remoteID: AnyObject? = valueForKey(localKey)

    return Sync.safeObjectInContext(context,
      entityName: self.entity.name!,
      remoteID: remoteID!)
  }

  private func sync_relationships() -> [NSRelationshipDescription] {
    var relationships = [NSRelationshipDescription]()

    for property in self.entity.properties {
      if let property = property as? NSRelationshipDescription {
        relationships.append(property)
      }
    }

    return relationships
  }

  private func sync_processToManyRelationship(relationship: NSRelationshipDescription, usingDictionary
    dictionary: [NSObject : AnyObject],
    parent: NSManagedObject?,
    dataStack: DATAStack) {

      let relationshipName = self.relationshipName(relationship)
      let childEntityName: String = relationship.destinationEntity!.name!
      let parentEntityName: String? = parent?.entity.name
      let inverseEntityName: String = relationship.inverseRelationship!.name
      let inverseIsToMany: Bool = relationship.inverseRelationship!.toMany
      let hasValidManyToManyRelationship = (parent != nil && inverseIsToMany && parentEntityName == childEntityName)

      if let children = dictionary[relationshipName] as? NSDictionary {
        var childPredicate = NSPredicate()
        let entity = NSEntityDescription.entityForName(childEntityName, inManagedObjectContext: self.managedObjectContext!)

        if inverseIsToMany {
          if let destinationRemoteKey = entity?.sync_remoteKey() {
            let childsIDs: AnyObject? = children[destinationRemoteKey]
            let destinationLocalKey = entity?.sync_localKey()

            if childsIDs!.count == 1 {
              childPredicate = NSPredicate(format: "%K = %@", destinationLocalKey!, (children.valueForKey(destinationRemoteKey)!.firstObject as? String)!)
            } else {
              childPredicate = NSPredicate(format: "ANY %K.%K = %@", relationshipName, destinationLocalKey!, (children.valueForKey(destinationRemoteKey) as? String)!)
            }
          }
        } else {
          childPredicate = NSPredicate(format: "%K = %@", inverseEntityName, self)
        }

        Sync.changes([children],
          entityName: childEntityName,
          predicate: childPredicate,
          parent: self,
          context: self.managedObjectContext!,
          dataStack: dataStack,
          completion: nil)

      } else if hasValidManyToManyRelationship {
        let relatedObjects = mutableSetValueForKey(relationshipName)
        relatedObjects.addObject(parent!)
        self.setValue(relatedObjects, forKey: relationshipName)
      }
  }

  private func sync_processToOneRelationship(relationship: NSRelationshipDescription,
    usingDictionary dictionary: [NSObject : AnyObject]) {
      let relationshipName = self.relationshipName(relationship)
      let entityName = relationship.destinationEntity?.name
      let entity = NSEntityDescription.entityForName(entityName!, inManagedObjectContext: self.managedObjectContext!)
      if let filteredObjectDictionary = dictionary[relationshipName] as? [NSObject : AnyObject] {
        if let remoteKey = entity?.sync_remoteKey(),
          remoteID = dictionary[remoteKey] as? String {
            if let object = Sync.safeObjectInContext(self.managedObjectContext!,
              entityName: entityName!,
              remoteID: remoteID) {
                object.hyp_fillWithDictionary(filteredObjectDictionary)
                self.setValue(object, forKey: relationship.name)
            } else if let object = NSEntityDescription.insertNewObjectForEntityForName(entityName!,
              inManagedObjectContext: self.managedObjectContext!) as? NSManagedObject {
                object.hyp_fillWithDictionary(filteredObjectDictionary)
                self.setValue(object, forKey: relationship.name)
            }
        }
      }
  }

}

@objc(HYP) public class Sync {

  static func safeObjectInContext(context: NSManagedObjectContext,
    entityName: String,
    remoteID: AnyObject) -> NSManagedObject? {
      var error: NSError?
      let entity = NSEntityDescription .entityForName(entityName,
        inManagedObjectContext: context)
      let request = NSFetchRequest(entityName: entityName)
      let localKey = entity?.sync_localKey()

      request.predicate = NSPredicate(format: "%K = \(remoteID)", localKey!)

      let objects = context.executeFetchRequest(request, error: &error)

      if (error != nil) {
        println("parentError: \(error)")
      }

      return objects?.first as? NSManagedObject
  }

  class func changes(changes: [AnyObject],
    entityName: String,
    dataStack: DATAStack,
    completion: ((error: NSError?) -> Void)?) {
      self.changes(changes,
        entityName: entityName,
        predicate: nil,
        dataStack: dataStack,
        completion: completion)
  }

  class func changes(changes: [AnyObject],
    entityName: String,
    predicate: NSPredicate?,
    dataStack: DATAStack,
    completion: ((error: NSError?) -> Void)?) {
      dataStack.performInNewBackgroundContext {
        (backgroundContext: NSManagedObjectContext!) in
        [self.changes(changes,
          entityName: entityName,
          predicate: predicate,
          parent:nil,
          context: backgroundContext,
          dataStack: dataStack,
          completion: completion)]
      }
  }

  class func changes(changes: [AnyObject],
    entityName: String,
    parent: NSManagedObject,
    dataStack: DATAStack,
    completion: ((error: NSError?) -> Void)?) {
      dataStack.performInNewBackgroundContext {
        (backgroundContext: NSManagedObjectContext!) in

        let safeParent = parent.sync_copyInContext(backgroundContext)
        let predicate = NSPredicate(format: "%K = %@", parent.entity.name!, safeParent!)

        self.changes(changes,
          entityName: entityName,
          predicate: predicate,
          parent:safeParent,
          context: backgroundContext,
          dataStack: dataStack,
          completion: completion)
      }
  }

  class func changes(changes: [AnyObject],
    entityName: String,
    predicate: NSPredicate?,
    parent: NSManagedObject?,
    context: NSManagedObjectContext!,
    dataStack: DATAStack,
    completion: ((error: NSError?) -> Void)?) {
      let entity = NSEntityDescription.entityForName(entityName,
        inManagedObjectContext: context)

      DATAFilter.changes(changes,
        inEntityNamed: entityName,
        localKey: entity!.sync_localKey(),
        remoteKey: entity!.sync_remoteKey(),
        context: context,
        predicate: predicate,
        inserted: {
          (JSON: [NSObject : AnyObject]!) in
          let createdObject: AnyObject = NSEntityDescription.insertNewObjectForEntityForName(entityName,
            inManagedObjectContext: context)
          createdObject.hyp_fillWithDictionary(JSON)
          createdObject.sync_processRelationshipsUsingDictionary(objectDictionary: JSON,
            parent: parent,
            dataStack: dataStack)
        }, updated: {
          (JSON: [NSObject : AnyObject]!, updatedObject: NSManagedObject!) in
          updatedObject.hyp_fillWithDictionary(JSON)
          updatedObject.sync_processRelationshipsUsingDictionary(objectDictionary: JSON,
            parent:parent,
            dataStack: dataStack)
      })

      var error: NSError?
      context.save(&error)

      if error != nil {
        println("Sync (error while saving \(entityName): \(error?.description)")
      }

      dataStack.persistWithCompletion {
        completion!(error: error)
      }
  }

}
