import CoreData
import NSEntityDescription_SYNCPrimaryKey
import DATAStack
import NSString_HYPNetworking

public extension NSManagedObject {
    func sync_copyInContext(context: NSManagedObjectContext) -> NSManagedObject {
        let entity = NSEntityDescription.entityForName(self.entity.name!, inManagedObjectContext: context)!
        let localKey = entity.sync_localKey()
        let remoteID = self.valueForKey(localKey)

        return context.sync_safeObject(self.entity.name!, remoteID: remoteID, parent: nil, parentRelationshipName: nil)!
    }

    /**
     Fills relationships using the received dictionary.
     */
    func sync_processRelationshipsUsingDictionary(objectDictionary: [String : AnyObject], parent: NSManagedObject?, dataStack: DATAStack) {
        let relationships = self.entity.sync_relationships()
        for relationship in relationships {
            let entity = NSEntityDescription.entityForName(relationship.entity.name!, inManagedObjectContext: self.managedObjectContext!)!
            let relationships = entity.relationshipsWithDestinationEntity(relationship.destinationEntity!)
            if relationships.count > 0 {
                let keyName = relationships.first!.name.hyp_remoteString().stringByAppendingString("_id")
                if relationship.toMany {
                    self.sync_processToManyRelationship(relationship, objectDictionary: objectDictionary, parent: parent, dataStack: dataStack)
                } else if relationship.destinationEntity?.name == parent?.entity.name {
                    let currentParent = self.valueForKey(relationship.name)
                    if currentParent == nil || parent != nil && !currentParent!.isEqual(parent!) {
                        self.setValue(parent, forKey: relationship.name)
                    }
                } else if let remoteID = objectDictionary[keyName] {
                    self.sync_processIDRelationship(relationship, remoteID: remoteID, parent: parent, dataStack: dataStack)
                } else {
                    self.sync_processToOneRelationship(relationship, objectDictionary: objectDictionary, parent: parent, dataStack: dataStack)
                }
            }
        }
    }

    func sync_processToManyRelationship(relationship: NSRelationshipDescription, objectDictionary: [String : AnyObject], parent: NSManagedObject?, dataStack: DATAStack) {
        let relationshipKey = relationship.userInfo?[SYNCCustomRemoteKey] as? String
        let relationshipName = (relationshipKey != nil) ? relationshipKey : relationship.name.hyp_remoteString()
        let childEntityName = relationship.destinationEntity!.name!
        let parentEntityName = parent?.entity.name
        let inverseEntityName = relationship.inverseRelationship?.name
        let inverseIsToMany = relationship.inverseRelationship?.toMany ?? false
        let hasValidManyToManyRelationship = parent != nil && parentEntityName != nil && inverseIsToMany && parentEntityName! == childEntityName
        if let children = objectDictionary[relationshipName] as? [[String : AnyObject]] {
            var childPredicate: NSPredicate? = nil
            if inverseIsToMany {
                let entity = NSEntityDescription.entityForName(childEntityName, inManagedObjectContext: self.managedObjectContext!)!
                let destinationRemoteKey = entity.sync_remoteKey()
                let childIDs = (children as NSArray).valueForKey(destinationRemoteKey)
                let destinationLocalKey = entity.sync_localKey()
                if childIDs.count > 0 {
                    childPredicate = NSPredicate(format: "ANY %K IN %@", destinationLocalKey, childIDs as! NSObject)
                }
            } else if let inverseEntityName = inverseEntityName {
                childPredicate = NSPredicate(format: "%K = %@", inverseEntityName, self)
            }

            Sync.changes(children, inEntityNamed: childEntityName, predicate: childPredicate, parent: self, inContext: self.managedObjectContext!, dataStack: dataStack, completion: nil)
        } else if hasValidManyToManyRelationship, let parent = parent {
            let relatedObjects = self.mutableSetValueForKey(relationship.name)
            if !relatedObjects.containsObject(parent) {
                relatedObjects.addObject(parent)
                self.setValue(relatedObjects, forKey: relationship.name)
            }
        }
    }

    func sync_processIDRelationship(relationship: NSRelationshipDescription, remoteID: AnyObject, parent: NSManagedObject?, dataStack: DATAStack) {
        let entityName = relationship.destinationEntity!.name!
        guard let object = self.managedObjectContext!.sync_safeObject(entityName, remoteID: remoteID, parent: self, parentRelationshipName: relationship.name) else { abort() }

        let currentRelationship = self.valueForKey(relationship.name)
        if currentRelationship == nil || !currentRelationship!.isEqual(object) {
            self.setValue(object, forKey: relationship.name)
        }
    }

    func sync_processToOneRelationship(relationship: NSRelationshipDescription, objectDictionary: [String : AnyObject], parent: NSManagedObject?, dataStack: DATAStack) {
        let relationshipKey = relationship.userInfo?[SYNCCustomRemoteKey] as? String
        let relationshipName = (relationshipKey != nil) ? relationshipKey : relationship.name.hyp_remoteString()
        let entityName = relationship.destinationEntity!.name!
        let entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: self.managedObjectContext!)!
        if let filteredObjectDictionary = objectDictionary[relationshipName] as? NSDictionary {
            var remoteID: AnyObject?
            if let remoteKey = entity.sync_remoteKey() {
                remoteID = filteredObjectDictionary[remoteKey]
            }
            let object = self.managedObjectContext!.sync_safeObject(entityName, remoteID: remoteID, parent: self, parentRelationshipName: relationship.name) ?? NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: self.managedObjectContext!)
            object.hyp_fillWithDictionary(filteredObjectDictionary as [NSObject : AnyObject])
            object.sync_processRelationshipsUsingDictionary(filteredObjectDictionary as! [String : AnyObject], parent: self, dataStack: dataStack)
            let currentRelationship = self.valueForKey(relationship.name)
            if currentRelationship == nil || !currentRelationship!.isEqual(object) {
                self.setValue(object, forKey: relationship.name)
            }
        }
    }
}
