import UIKit
import CoreData
import NSString_HYPNetworking
import DATAStack
import DATAFilter
import NSManagedObject_HYPPropertyMapper
import NSDictionary_ANDYSafeValue

let CustomPrimaryKey = "hyper.isPrimaryKey"
let CustomRemoteKey = "hyper.remoteKey"
let DefaultLocalPrimaryKey = "remoteID"
let DefaultRemotePrimaryKey = "id"

private extension NSEntityDescription {

  func sync_localKey() -> String {
    var localKey: String?

    for (key, attributedDescription) in self.propertiesByName {
      if let userInfo: Dictionary = attributedDescription.userInfo,
        customPrimaryKey = userInfo[CustomPrimaryKey] as? String where customPrimaryKey == "YES" {
          localKey = key as? String
      }
    }

    if !(localKey != nil) {
      localKey = DefaultLocalPrimaryKey
    }

    return localKey!
  }

  func sync_remoteKey() -> String {
    var remoteKey: String?
    let localKey = sync_localKey()

    if localKey == remoteKey {
      remoteKey = DefaultRemotePrimaryKey
    } else {
      remoteKey = localKey.hyp_remoteString()
    }

    return remoteKey!
  }

}

public extension NSManagedObject {

  private func sync_copyInContext(context: NSManagedObjectContext) -> NSManagedObject? {
    let entity = NSEntityDescription.entityForName(self.entity.name!,
        inManagedObjectContext: context)

    let localKey = entity!.sync_localKey()
//    let remoteID = self.valueForKey(localKey)
// TODO: Implement this
    return nil
  }

  private func sync_relationships() -> [NSRelationshipDescription] {
    var relationships: [NSRelationshipDescription] = []

    for property in self.entity.properties {
      if property is NSRelationshipDescription {
        relationships.append(property as! NSRelationshipDescription)
      }
    }

    return relationships
  }

  private func sync_processRelationshipsUsingDictionary(objectDictionary dictionary: [NSObject : AnyObject], andParent parent: NSManagedObject?, dataStack: DATAStack) {
    let relationships = self.sync_relationships()

    for relationship: NSRelationshipDescription in relationships {
      if relationship.toMany {
        // TODO : Implement this
      } else if parent != nil && relationship.destinationEntity?.name == parent?.entity.name! {
        self.setValue(parent, forKey: relationship.name)
      } else {
        // TODO : Implement this
      }
    }
  }

  private func sync_processToManyRelationship(relationship: NSRelationshipDescription, usingDictionary dictionary: Dictionary<String, AnyObject>, andParent parent: NSManagedObject!, datastack: DATAStack) {

    var relationshipName: String
    if let userInfo: Dictionary = relationship.userInfo,
      relationshipKey = userInfo[CustomRemoteKey] as? String {
        relationshipName = relationshipKey
    } else {
      relationshipName = relationship.name
    }

    let childEntityName: String = relationship.destinationEntity!.name!
    let parentEntityName: String = parent.entity.name!
    let inverseEntityName: String = relationship.inverseRelationship!.name
    let inverseIsToMany: Bool = relationship.inverseRelationship!.toMany
    let hasValidManyToManyRelationship = (parent != nil && inverseIsToMany && parentEntityName == childEntityName)

    if let children = dictionary[relationshipName] as? [AnyObject?] {
      var childPredicate: NSPredicate
      let entity = NSEntityDescription.entityForName(childEntityName, inManagedObjectContext: self.managedObjectContext!)

      if inverseIsToMany {
      // TODO: Implement this
//        if let destinationRemoteKey = entity?.sync_remoteKey() ,
//          childIDs: [String] = children[destinationRemoteKey],
//          destinationLocalKey = entity?.sync_localKey() {
//            if childIDs.count == 1 {
//            }
//        }
      } else {
        // TODO: Implement this
      }

    }
  }

}

struct Sync {

  func process(#changes: [AnyObject],
    inEntityNamed entityName: String,
    dataStack: DATAStack,
    completion: (error: NSError) -> Void) {
      [self.process(changes: changes,
        inEntityNamed: entityName,
        predicate: nil,
        dataStack: dataStack,
        completion: completion)]
  }

  func process(#changes: [AnyObject],
    inEntityNamed entityName: String,
    predicate: NSPredicate?,
    dataStack: DATAStack,
    completion: (error: NSError) -> Void) {
      dataStack.performInNewBackgroundContext {
        (backgroundContext: NSManagedObjectContext!) in
        [self.process(changes: changes,
          inEntityNamed: entityName,
          predicate: nil,
          parent:nil,
          inContext: backgroundContext,
          dataStack: dataStack,
          completion: completion)]
      }
  }

  func process(#changes: [AnyObject],
    inEntityNamed entityName: String,
    predicate: NSPredicate?,
    parent: NSManagedObject,
    dataStack: DATAStack,
    completion: (error: NSError) -> Void) {
      dataStack.performInNewBackgroundContext {
        (backgroundContext: NSManagedObjectContext!) in

        let safeParent = parent.sync_copyInContext(backgroundContext)
        let predicate = NSPredicate(format: "%K = %@", parent.entity.name!, safeParent!)

        [self.process(changes: changes,
          inEntityNamed: entityName,
          predicate: predicate,
          parent:parent,
          inContext: backgroundContext,
          dataStack: dataStack,
          completion: completion)]
      }
  }

  func process(#changes: [AnyObject],
    inEntityNamed entityName: String,
    predicate: NSPredicate?,
    parent: NSManagedObject?,
    inContext context: NSManagedObjectContext,
    dataStack: DATAStack,
    completion: (error: NSError) -> Void) {
      let entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: context)

      DATAFilter.changes(changes,
        inEntityNamed: entityName,
        localKey: entity!.sync_localKey(),
        remoteKey: entity!.sync_remoteKey(),
        context: context,
        predicate: predicate,
        inserted: {
          (JSON: [NSObject : AnyObject]!) in
          let created: AnyObject = NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: context)
          created.hyp_fillWithDictionary(JSON)
          // TODO: Implement this
        }, updated: {
          (JSON: [NSObject : AnyObject]!, updatedObject: NSManagedObject!) in
          // TODO: Implement this
      })
  }

}
