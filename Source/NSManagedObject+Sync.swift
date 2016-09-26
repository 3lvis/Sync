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
    func sync_copyInContext(context: NSManagedObjectContext) -> NSManagedObject {
        guard let entityName = entity.name, entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: context) else { abort() }
        let localPrimaryKey = valueForKey(entity.sync_localPrimaryKey())
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
    func sync_fillWithDictionary(dictionary: [String : AnyObject], parent: NSManagedObject?, parentRelationship: NSRelationshipDescription?, dataStack: DATAStack, operations: DATAFilter.Operation) {
        hyp_fillWithDictionary(dictionary)

        for relationship in entity.sync_relationships() {
            let suffix = relationship.toMany ? "_ids" : "_id"
            let constructedKeyName = relationship.name.hyp_remoteString() + suffix
            let keyName = relationship.userInfo?[SYNCCustomRemoteKey] as? String ?? constructedKeyName

            if relationship.toMany {
                if let localPrimaryKey = dictionary[keyName] where localPrimaryKey is Array<String> || localPrimaryKey is Array<Int> || localPrimaryKey is NSNull {
                    sync_toManyRelationshipUsingIDsInsteadOfDictionary(relationship, localPrimaryKey: localPrimaryKey)
                } else {
                    sync_toManyRelationship(relationship, dictionary: dictionary, parent: parent, parentRelationship: parentRelationship, dataStack: dataStack, operations: operations)
                }
            } else if let parent = parent where !parent.isEqual(valueForKey(relationship.name)) && relationship.destinationEntity?.name == parent.entity.name || relationship.destinationEntity?.name == parent.entity.superentity?.name {
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
    func sync_toManyRelationshipUsingIDsInsteadOfDictionary(relationship: NSRelationshipDescription, localPrimaryKey: AnyObject) {
        guard let managedObjectContext = managedObjectContext else { fatalError("managedObjectContext not found") }
        guard let destinationEntity = relationship.destinationEntity else { fatalError("destinationEntity not found in relationship: \(relationship)") }
        guard let destinationEntityName = destinationEntity.name else { fatalError("entityName not found in entity: \(destinationEntity)") }
        guard let entity = NSEntityDescription.entityForName(destinationEntityName, inManagedObjectContext: managedObjectContext) else { return }
        if localPrimaryKey is NSNull {
            if valueForKey(relationship.name) != nil {
                setValue(nil, forKey: relationship.name)
            }
        } else {
            guard let remoteItems = localPrimaryKey as? NSArray else { return }
            let localRelationship: NSSet
            if relationship.ordered {
                let value = self.valueForKey(relationship.name) as? NSOrderedSet ?? NSOrderedSet()
                localRelationship = value.set
            } else {
                localRelationship = self.valueForKey(relationship.name) as? NSSet ?? NSSet()
            }
            let localItems = localRelationship.valueForKey(entity.sync_localPrimaryKey()) as? NSSet ?? NSSet()

            let deletedItems = NSMutableArray(array: localItems.allObjects)
            deletedItems.removeObjectsInArray(remoteItems as [AnyObject])

            let insertedItems = remoteItems.mutableCopy() as? NSMutableArray ?? NSMutableArray()
            insertedItems.removeObjectsInArray(localItems.allObjects)

            guard insertedItems.count > 0 || deletedItems.count > 0 else { return }
            let request = NSFetchRequest(entityName: destinationEntityName)
            let fetchedObjects = try? managedObjectContext.executeFetchRequest(request) as? [NSManagedObject] ?? [NSManagedObject]()
            guard let objects = fetchedObjects else { return }
            for safeObject in objects {
                let currentID = safeObject.valueForKey(entity.sync_localPrimaryKey())!
                for inserted in insertedItems {
                    if currentID.isEqual(inserted) {
                        if relationship.ordered {
                            let relatedObjects = mutableOrderedSetValueForKey(relationship.name)
                            if !relatedObjects.containsObject(safeObject) {
                                relatedObjects.addObject(safeObject)
                                setValue(relatedObjects, forKey: relationship.name)
                            }
                        } else {
                            let relatedObjects = mutableSetValueForKey(relationship.name)
                            if !relatedObjects.containsObject(safeObject) {
                                relatedObjects.addObject(safeObject)
                                setValue(relatedObjects, forKey: relationship.name)
                            }
                        }
                    }
                }

                for deleted in deletedItems {
                    if currentID.isEqual(deleted) {
                        if relationship.ordered {
                            let relatedObjects = mutableOrderedSetValueForKey(relationship.name)
                            if relatedObjects.containsObject(safeObject) {
                                relatedObjects.removeObject(safeObject)
                                setValue(relatedObjects, forKey: relationship.name)
                            }
                        } else {
                            let relatedObjects = mutableSetValueForKey(relationship.name)
                            if relatedObjects.containsObject(safeObject) {
                                relatedObjects.removeObject(safeObject)
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
    func sync_toManyRelationship(relationship: NSRelationshipDescription, dictionary: [String : AnyObject], parent: NSManagedObject?, parentRelationship: NSRelationshipDescription?, dataStack: DATAStack, operations: DATAFilter.Operation) {
        var children: [[String : AnyObject]]?
        let childrenIsNull = relationship.userInfo?[SYNCCustomRemoteKey] is NSNull || dictionary[relationship.name.hyp_remoteString()] is NSNull || dictionary[relationship.name] is NSNull
        if childrenIsNull {
            children = [[String : AnyObject]]()

            if valueForKey(relationship.name) != nil {
                setValue(nil, forKey: relationship.name)
            }
        } else {
            if let customRelationshipName = relationship.userInfo?[SYNCCustomRemoteKey] as? String {
                children = dictionary[customRelationshipName] as? [[String : AnyObject]]
            } else if let result = dictionary[relationship.name.hyp_remoteString()] as? [[String : AnyObject]] {
                children = result
            } else if let result = dictionary[relationship.name] as? [[String : AnyObject]] {
                children = result
            }
        }

        let inverseIsToMany = relationship.inverseRelationship?.toMany ?? false
        guard let managedObjectContext = managedObjectContext else { abort() }
        guard let destinationEntity = relationship.destinationEntity else { abort() }
        guard let childEntityName = destinationEntity.name else { abort() }

        if let children = children {
            let childIDs = (children as NSArray).valueForKey(destinationEntity.sync_remotePrimaryKey())

            if childIDs is NSNull {
                if valueForKey(relationship.name) != nil {
                    setValue(nil, forKey: relationship.name)
                }
            } else {
                guard let destinationEntityName = destinationEntity.name else { fatalError("entityName not found in entity: \(destinationEntity)") }
                if let remoteItems = childIDs as? NSArray {
                    let localRelationship: NSSet
                    if relationship.ordered {
                        let value = self.valueForKey(relationship.name) as? NSOrderedSet ?? NSOrderedSet()
                        localRelationship = value.set
                    } else {
                        localRelationship = self.valueForKey(relationship.name) as? NSSet ?? NSSet()
                    }
                    let localItems = localRelationship.valueForKey(destinationEntity.sync_localPrimaryKey()) as? NSSet ?? NSSet()

                    let deletedItems = NSMutableArray(array: localItems.allObjects)
                    deletedItems.removeObjectsInArray(remoteItems as [AnyObject])

                    if deletedItems.count > 0 {
                        let request = NSFetchRequest(entityName: destinationEntityName)

                        do {
                            let safeLocalObjects = try managedObjectContext.executeFetchRequest(request) as? [NSManagedObject] ?? [NSManagedObject]()
                            for safeObject in safeLocalObjects {
                                let currentID = safeObject.valueForKey(destinationEntity.sync_localPrimaryKey())!
                                for deleted in deletedItems {
                                    if currentID.isEqual(deleted) {
                                        if relationship.ordered {
                                            let relatedObjects = mutableOrderedSetValueForKey(relationship.name)
                                            if relatedObjects.containsObject(safeObject) {
                                                relatedObjects.removeObject(safeObject)
                                                setValue(relatedObjects, forKey: relationship.name)
                                            }
                                        } else {
                                            let relatedObjects = mutableSetValueForKey(relationship.name)
                                            if relatedObjects.containsObject(safeObject) {
                                                relatedObjects.removeObject(safeObject)
                                                setValue(relatedObjects, forKey: relationship.name)
                                            }
                                        }
                                    }
                                }
                            }
                        } catch {
                            fatalError()
                        }
                    }
                }
            }

            var childPredicate: NSPredicate?
            let manyToMany = inverseIsToMany && relationship.toMany
            if manyToMany {
                if childIDs.count > 0 {
                    guard let entity = NSEntityDescription.entityForName(childEntityName, inManagedObjectContext: managedObjectContext) else { fatalError() }
                    guard let childIDsObject = childIDs as? NSObject else { fatalError() }
                    childPredicate = NSPredicate(format: "ANY %K IN %@", entity.sync_localPrimaryKey(), childIDsObject)
                }
            } else {
                guard let inverseEntityName = relationship.inverseRelationship?.name else { fatalError() }
                childPredicate = NSPredicate(format: "%K = %@", inverseEntityName, self)
            }

            Sync.changes(children, inEntityNamed: childEntityName, predicate: childPredicate, parent: self, parentRelationship: relationship, inContext: managedObjectContext, dataStack: dataStack, operations: operations, completion: nil)
        } else if let parent = parent, entityName = parent.entity.name where inverseIsToMany && entityName == childEntityName && parentRelationship?.inverseRelationship == relationship {
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
     - parameter localPrimaryKey: The localPrimaryKey of the relationship to be synced, usually a number or an integer.
     - parameter dataStack: The DATAStack instance.
     */
    func sync_toOneRelationshipUsingIDInsteadOfDictionary(relationship: NSRelationshipDescription, localPrimaryKey: AnyObject, dataStack: DATAStack) {
        guard let managedObjectContext = managedObjectContext else { fatalError("managedObjectContext not found") }
        guard let destinationEntity = relationship.destinationEntity else { fatalError("destinationEntity not found in relationship: \(relationship)") }
        guard let destinationEntityName = destinationEntity.name else { fatalError("entityName not found in entity: \(destinationEntity)") }
        if localPrimaryKey is NSNull {
            if valueForKey(relationship.name) != nil {
                setValue(nil, forKey: relationship.name)
            }
        } else if let safeObject = managedObjectContext.sync_safeObject(destinationEntityName, localPrimaryKey: localPrimaryKey, parent: self, parentRelationshipName: relationship.name) {
            let currentRelationship = valueForKey(relationship.name)
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
    func sync_toOneRelationship(relationship: NSRelationshipDescription, dictionary: [String : AnyObject], dataStack: DATAStack, operations: DATAFilter.Operation) {
        var filteredObjectDictionary: [String : AnyObject]?

        if let customRelationshipName = relationship.userInfo?[SYNCCustomRemoteKey] as? String {
            filteredObjectDictionary = dictionary[customRelationshipName] as? [String : AnyObject]
        } else if let result = dictionary[relationship.name.hyp_remoteString()] as? [String : AnyObject] {
            filteredObjectDictionary = result
        } else if let result = dictionary[relationship.name] as? [String : AnyObject] {
            filteredObjectDictionary = result
        }

        guard let toOneObjectDictionary = filteredObjectDictionary else { return }
        guard let managedObjectContext = self.managedObjectContext else { return }
        guard let destinationEntity = relationship.destinationEntity else { return }
        guard let entityName = destinationEntity.name else { return }
        guard let entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: managedObjectContext) else { return }

        let localPrimaryKey = toOneObjectDictionary[entity.sync_remotePrimaryKey()]
        let object = managedObjectContext.sync_safeObject(entityName, localPrimaryKey: localPrimaryKey, parent: self, parentRelationshipName: relationship.name) ?? NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: managedObjectContext)

        object.sync_fillWithDictionary(toOneObjectDictionary, parent: self, parentRelationship: relationship, dataStack: dataStack, operations: operations)

        let currentRelationship = valueForKey(relationship.name)
        if currentRelationship == nil || !currentRelationship!.isEqual(object) {
            setValue(object, forKey: relationship.name)
        }
    }
}
