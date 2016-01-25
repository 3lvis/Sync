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
        let entity = NSEntityDescription.entityForName(self.entity.name!, inManagedObjectContext: context)!
        let localKey = entity.sync_localKey()
        let remoteID = self.valueForKey(localKey)

        return context.sync_safeObject(self.entity.name!, remoteID: remoteID, parent: nil, parentRelationshipName: nil)!
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
        self.hyp_fillWithDictionary(dictionary)

        let relationships = self.entity.sync_relationships()
        for relationship in relationships {
            let entity = NSEntityDescription.entityForName(relationship.entity.name!, inManagedObjectContext: self.managedObjectContext!)!
            let relationships = entity.relationshipsWithDestinationEntity(relationship.destinationEntity!)
            if relationships.count > 0 {
                let keyName = relationships.first!.name.hyp_remoteString().stringByAppendingString("_id")
                if relationship.toMany {
                    self.sync_toManyRelationship(relationship, dictionary: dictionary, parent: parent, dataStack: dataStack)
                } else if relationship.destinationEntity?.name == parent?.entity.name {
                    let currentParent = self.valueForKey(relationship.name)
                    if currentParent == nil || parent != nil && !currentParent!.isEqual(parent!) {
                        self.setValue(parent, forKey: relationship.name)
                    }
                } else if let remoteID = dictionary[keyName] {
                    self.sync_relationshipUsingIDInsteadOfDictionary(relationship, remoteID: remoteID, dataStack: dataStack)
                } else {
                    self.sync_toOneRelationship(relationship, dictionary: dictionary, dataStack: dataStack)
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
    func sync_toManyRelationship(relationship: NSRelationshipDescription, dictionary: [String : AnyObject], parent: NSManagedObject?, dataStack: DATAStack) {
        let relationshipKey = relationship.userInfo?[SYNCCustomRemoteKey] as? String
        let relationshipName = (relationshipKey != nil) ? relationshipKey : relationship.name.hyp_remoteString()
        let childEntityName = relationship.destinationEntity!.name!
        let parentEntityName = parent?.entity.name
        let inverseEntityName = relationship.inverseRelationship?.name
        let inverseIsToMany = relationship.inverseRelationship?.toMany ?? false
        let hasValidManyToManyRelationship = parent != nil && parentEntityName != nil && inverseIsToMany && parentEntityName! == childEntityName
        if let children = dictionary[relationshipName] as? [[String : AnyObject]] {
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
            if relationship.ordered {
                let relatedObjects = self.mutableOrderedSetValueForKey(relationship.name)
                if !relatedObjects.containsObject(parent) {
                    relatedObjects.addObject(parent)
                    self.setValue(relatedObjects, forKey: relationship.name)
                }
            } else {
                let relatedObjects = self.mutableSetValueForKey(relationship.name)
                if !relatedObjects.containsObject(parent) {
                    relatedObjects.addObject(parent)
                    self.setValue(relatedObjects, forKey: relationship.name)
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
        let entityName = relationship.destinationEntity!.name!
        guard let object = self.managedObjectContext!.sync_safeObject(entityName, remoteID: remoteID, parent: self, parentRelationshipName: relationship.name) else { abort() }

        let currentRelationship = self.valueForKey(relationship.name)
        if currentRelationship == nil || !currentRelationship!.isEqual(object) {
            self.setValue(object, forKey: relationship.name)
        }
    }

    /**
     Syncs the entity's to-one relationship, it will also sync the child of this entity.
     - parameter relationship: The relationship to be synced.
     - parameter dictionary: The JSON with the changes to be applied to the entity.
     - parameter dataStack: The DATAStack instance.
     */
    func sync_toOneRelationship(relationship: NSRelationshipDescription, dictionary: [String : AnyObject], dataStack: DATAStack) {
        let relationshipKey = relationship.userInfo?[SYNCCustomRemoteKey] as? String
        let relationshipName = (relationshipKey != nil) ? relationshipKey : relationship.name.hyp_remoteString()
        let entityName = relationship.destinationEntity!.name!
        let entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: self.managedObjectContext!)!
        if let filteredObjectDictionary = dictionary[relationshipName] as? NSDictionary {
            var remoteID: AnyObject?
            if let remoteKey = entity.sync_remoteKey() {
                remoteID = filteredObjectDictionary[remoteKey]
            }
            let object = self.managedObjectContext!.sync_safeObject(entityName, remoteID: remoteID, parent: self, parentRelationshipName: relationship.name) ?? NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: self.managedObjectContext!)
            object.sync_fillWithDictionary(filteredObjectDictionary as! [String : AnyObject], parent: self, dataStack: dataStack)
            let currentRelationship = self.valueForKey(relationship.name)
            if currentRelationship == nil || !currentRelationship!.isEqual(object) {
                self.setValue(object, forKey: relationship.name)
            }
        }
    }
}
