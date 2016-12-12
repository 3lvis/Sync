import CoreData
import DATAStack
import SYNCPropertyMapper

extension NSManagedObject {
    /**
     Using objectID to fetch an NSManagedObject from a NSManagedContext is quite unsafe,
     and has unexpected behaviour most of the time, although it has gotten better throught
     the years, it's a simple method with not many moving parts.

     Copy in context gives you a similar behaviour, just a bit safer.
     - parameter context: The context where the NSManagedObject will be taken
     - returns: A NSManagedObject copied in the provided context.
     */
    func sync_copyInContext(_ context: NSManagedObjectContext) -> NSManagedObject {
        guard let entityName = self.entity.name else { fatalError("Couldn't find entity name") }
        let localPrimaryKey = value(forKey: self.entity.sync_localPrimaryKey())
        guard let copiedObject = context.safeObject(entityName, localPrimaryKey: localPrimaryKey, parent: nil, parentRelationshipName: nil) else { fatalError("Couldn't fetch a safe object from entityName: \(entityName) localPrimaryKey: \(localPrimaryKey)") }

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
    func sync_fill(with dictionary: [String: Any], parent: NSManagedObject?, parentRelationship: NSRelationshipDescription?, context: NSManagedObjectContext, operations: Sync.OperationOptions, shouldContinueBlock: (() -> Bool)?, objectJSONBlock: ((_ objectJSON: [String: Any]) -> [String: Any])?) {
        hyp_fill(with: dictionary)

        for relationship in entity.sync_relationships() {
            let suffix = relationship.isToMany ? "_ids" : "_id"
            let constructedKeyName = relationship.name.hyp_snakeCase() + suffix
            let keyName = relationship.userInfo?[SYNCCustomRemoteKey] as? String ?? constructedKeyName

            if relationship.isToMany {
                if let localPrimaryKey = dictionary[keyName], localPrimaryKey is Array < String> || localPrimaryKey is Array < Int> || localPrimaryKey is NSNull {
                    sync_toManyRelationshipUsingIDsInsteadOfDictionary(relationship, localPrimaryKey: localPrimaryKey)
                } else {
                    try! sync_toManyRelationship(relationship, dictionary: dictionary, parent: parent, parentRelationship: parentRelationship, context: context, operations: operations, shouldContinueBlock: shouldContinueBlock, objectJSONBlock: objectJSONBlock)
                }
            } else {
                var destinationIsParentSuperEntity = false
                if let parent = parent, let destinationEntityName = relationship.destinationEntity?.name {
                    if let parentSuperEntityName = parent.entity.superentity?.name {
                        destinationIsParentSuperEntity = destinationEntityName == parentSuperEntityName
                    }
                }

                var parentRelationshipIsTheSameAsCurrentRelationship = false
                if let parentRelationship = parentRelationship {
                    parentRelationshipIsTheSameAsCurrentRelationship = parentRelationship.inverseRelationship == relationship
                }

                if let parent = parent, parentRelationshipIsTheSameAsCurrentRelationship || destinationIsParentSuperEntity {
                    let currentValueForRelationship = self.value(forKey: relationship.name)
                    let newParentIsDifferentThanCurrentValue = parent.isEqual(currentValueForRelationship) == false
                    if newParentIsDifferentThanCurrentValue {
                        self.setValue(parent, forKey: relationship.name)
                    }
                } else if let localPrimaryKey = dictionary[keyName], localPrimaryKey is NSString || localPrimaryKey is NSNumber || localPrimaryKey is NSNull {
                    sync_toOneRelationshipUsingIDInsteadOfDictionary(relationship, localPrimaryKey: localPrimaryKey)
                } else {
                    sync_toOneRelationship(relationship, dictionary: dictionary, context: context, operations: operations, shouldContinueBlock: shouldContinueBlock, objectJSONBlock: objectJSONBlock)
                }
            }
        }
    }

    /**
     Syncs relationships where only the ids are present, for example if your model is: User <<->> Tags (a user has many tags and a tag belongs to many users),
     and your tag has a users_ids, it will try to sync using those ID instead of requiring you to provide the entire users list inside each tag.
     - parameter relationship: The relationship to be synced.
     - parameter localPrimaryKey: The localPrimaryKey of the relationship to be synced, usually an array of strings or numbers.
     */
    func sync_toManyRelationshipUsingIDsInsteadOfDictionary(_ relationship: NSRelationshipDescription, localPrimaryKey: Any) {
        guard let managedObjectContext = managedObjectContext else { fatalError("managedObjectContext not found") }
        guard let destinationEntity = relationship.destinationEntity else { fatalError("destinationEntity not found in relationship: \(relationship)") }
        guard let destinationEntityName = destinationEntity.name else { fatalError("entityName not found in entity: \(destinationEntity)") }
        if localPrimaryKey is NSNull {
            if value(forKey: relationship.name) != nil {
                setValue(nil, forKey: relationship.name)
            }
        } else {
            guard let remoteItems = localPrimaryKey as? NSArray else { return }
            let localRelationship: NSSet
            if relationship.isOrdered {
                let value = self.value(forKey: relationship.name) as? NSOrderedSet ?? NSOrderedSet()
                localRelationship = value.set as NSSet
            } else {
                localRelationship = self.value(forKey: relationship.name) as? NSSet ?? NSSet()
            }
            let localItems = localRelationship.value(forKey: destinationEntity.sync_localPrimaryKey()) as? NSSet ?? NSSet()

            let deletedItems = NSMutableArray(array: localItems.allObjects)
            let removedRemoteItems = remoteItems as? [Any] ?? [Any]()
            deletedItems.removeObjects(in: removedRemoteItems)

            let insertedItems = remoteItems.mutableCopy() as? NSMutableArray ?? NSMutableArray()
            insertedItems.removeObjects(in: localItems.allObjects)

            guard insertedItems.count > 0 || deletedItems.count > 0 || (insertedItems.count == 0 && deletedItems.count == 0 && relationship.isOrdered) else { return }
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: destinationEntityName)
            let fetchedObjects = try? managedObjectContext.fetch(request) as? [NSManagedObject] ?? [NSManagedObject]()
            guard let objects = fetchedObjects else { return }
            for safeObject in objects {
                let currentID = safeObject.value(forKey: safeObject.entity.sync_localPrimaryKey())!
                for inserted in insertedItems {
                    if (currentID as AnyObject).isEqual(inserted) {
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
                    if (currentID as AnyObject).isEqual(deleted) {
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

            if relationship.isOrdered {
                for safeObject in objects {
                    let currentID = safeObject.value(forKey: safeObject.entity.sync_localPrimaryKey())!
                    let remoteIndex = remoteItems.index(of: currentID)
                    let relatedObjects = self.mutableOrderedSetValue(forKey: relationship.name)

                    let currentIndex = relatedObjects.index(of: safeObject)
                    if currentIndex != remoteIndex {
                        relatedObjects.moveObjects(at: IndexSet(integer: currentIndex), to: remoteIndex)
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
    func sync_toManyRelationship(_ relationship: NSRelationshipDescription, dictionary: [String: Any], parent: NSManagedObject?, parentRelationship: NSRelationshipDescription?, context: NSManagedObjectContext, operations: Sync.OperationOptions, shouldContinueBlock: (() -> Bool)?, objectJSONBlock: ((_ objectJSON: [String: Any]) -> [String: Any])?) throws {
        var children: [[String: Any]]?
        let childrenIsNull = relationship.userInfo?[SYNCCustomRemoteKey] is NSNull || dictionary[relationship.name.hyp_snakeCase()] is NSNull || dictionary[relationship.name] is NSNull
        if childrenIsNull {
            children = [[String: Any]]()

            if value(forKey: relationship.name) != nil {
                setValue(nil, forKey: relationship.name)
            }
        } else {
            if let customRelationshipName = relationship.userInfo?[SYNCCustomRemoteKey] as? String {
                children = dictionary[customRelationshipName] as? [[String: Any]]
            } else if let result = dictionary[relationship.name.hyp_snakeCase()] as? [[String: Any]] {
                children = result
            } else if let result = dictionary[relationship.name] as? [[String: Any]] {
                children = result
            }
        }

        let inverseIsToMany = relationship.inverseRelationship?.isToMany ?? false
        guard let managedObjectContext = managedObjectContext else { abort() }
        guard let destinationEntity = relationship.destinationEntity else { abort() }
        guard let childEntityName = destinationEntity.name else { abort() }

        if let children = children {
            let childIDs = (children as NSArray).value(forKey: destinationEntity.sync_remotePrimaryKey())

            if childIDs is NSNull {
                if value(forKey: relationship.name) != nil {
                    setValue(nil, forKey: relationship.name)
                }
            } else {
                guard let destinationEntityName = destinationEntity.name else { fatalError("entityName not found in entity: \(destinationEntity)") }
                if let remoteItems = childIDs as? NSArray {
                    let localRelationship: NSSet
                    if relationship.isOrdered {
                        let value = self.value(forKey: relationship.name) as? NSOrderedSet ?? NSOrderedSet()
                        localRelationship = value.set as NSSet
                    } else {
                        localRelationship = self.value(forKey: relationship.name) as? NSSet ?? NSSet()
                    }
                    let localItems = localRelationship.value(forKey: destinationEntity.sync_localPrimaryKey()) as? NSSet ?? NSSet()

                    let deletedItems = NSMutableArray(array: localItems.allObjects)
                    let removedRemoteItems = remoteItems as? [Any] ?? [Any]()
                    deletedItems.removeObjects(in: removedRemoteItems)

                    let request = NSFetchRequest<NSFetchRequestResult>(entityName: destinationEntityName)
                    var safeLocalObjects: [NSManagedObject]?

                    if deletedItems.count > 0 {
                        safeLocalObjects = try managedObjectContext.fetch(request) as? [NSManagedObject] ?? [NSManagedObject]()
                        for safeObject in safeLocalObjects! {
                            let currentID = safeObject.value(forKey: safeObject.entity.sync_localPrimaryKey())!
                            for deleted in deletedItems {
                                if (currentID as AnyObject).isEqual(deleted) {
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

                    if relationship.isOrdered {
                        let objects: [NSManagedObject]
                        if let safeLocalObjects = safeLocalObjects {
                            objects = safeLocalObjects
                        } else {
                            objects = try managedObjectContext.fetch(request) as? [NSManagedObject] ?? [NSManagedObject]()
                        }
                        for safeObject in objects {
                            let currentID = safeObject.value(forKey: safeObject.entity.sync_localPrimaryKey())!
                            let remoteIndex = remoteItems.index(of: currentID)
                            let relatedObjects = self.mutableOrderedSetValue(forKey: relationship.name)

                            let currentIndex = relatedObjects.index(of: safeObject)
                            if currentIndex != remoteIndex && currentIndex != NSNotFound {
                                relatedObjects.moveObjects(at: IndexSet(integer: currentIndex), to: remoteIndex)
                            }
                        }
                    }
                }
            }

            var childPredicate: NSPredicate?
            let manyToMany = inverseIsToMany && relationship.isToMany
            if manyToMany {
                if ((childIDs as Any) as AnyObject).count > 0 {
                    guard let entity = NSEntityDescription.entity(forEntityName: childEntityName, in: managedObjectContext) else { fatalError() }
                    guard let childIDsObject = childIDs as? NSObject else { fatalError() }
                    childPredicate = NSPredicate(format: "ANY %K IN %@", entity.sync_localPrimaryKey(), childIDsObject)
                }
            } else {
                guard let inverseEntityName = relationship.inverseRelationship?.name else { fatalError() }
                childPredicate = NSPredicate(format: "%K = %@", inverseEntityName, self)
            }

            try Sync.changes(children, inEntityNamed: childEntityName, predicate: childPredicate, parent: self, parentRelationship: relationship, inContext: managedObjectContext, operations: operations, shouldContinueBlock: shouldContinueBlock, objectJSONBlock: objectJSONBlock)
        } else {
            var destinationIsParentSuperEntity = false
            if let parent = parent, let destinationEntityName = relationship.destinationEntity?.name {
                if let parentSuperEntityName = parent.entity.superentity?.name {
                    destinationIsParentSuperEntity = destinationEntityName == parentSuperEntityName
                }
            }

            var parentRelationshipIsTheSameAsCurrentRelationship = false
            if let parentRelationship = parentRelationship {
                parentRelationshipIsTheSameAsCurrentRelationship = parentRelationship.inverseRelationship == relationship
            }

            if let parent = parent, parentRelationshipIsTheSameAsCurrentRelationship || destinationIsParentSuperEntity {
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
    }

    /**
     Syncs relationships where only the id is present, for example if your model is: Company -> Employee,
     and your employee has a company_id, it will try to sync using that ID instead of requiring you to provide the
     entire company object inside the employees dictionary.
     - parameter relationship: The relationship to be synced.
     - parameter localPrimaryKey: The localPrimaryKey of the relationship to be synced, usually a number or an integer.
     - parameter dataStack: The DATAStack instance.
     */
    func sync_toOneRelationshipUsingIDInsteadOfDictionary(_ relationship: NSRelationshipDescription, localPrimaryKey: Any) {
        guard let managedObjectContext = self.managedObjectContext else { fatalError("managedObjectContext not found") }
        guard let destinationEntity = relationship.destinationEntity else { fatalError("destinationEntity not found in relationship: \(relationship)") }
        guard let destinationEntityName = destinationEntity.name else { fatalError("entityName not found in entity: \(destinationEntity)") }
        if localPrimaryKey is NSNull {
            if value(forKey: relationship.name) != nil {
                setValue(nil, forKey: relationship.name)
            }
        } else if let safeObject = managedObjectContext.safeObject(destinationEntityName, localPrimaryKey: localPrimaryKey, parent: self, parentRelationshipName: relationship.name) {
            let currentRelationship = value(forKey: relationship.name)
            if currentRelationship == nil || !(currentRelationship! as AnyObject).isEqual(safeObject) {
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
    func sync_toOneRelationship(_ relationship: NSRelationshipDescription, dictionary: [String: Any], context: NSManagedObjectContext, operations: Sync.OperationOptions, shouldContinueBlock: (() -> Bool)?, objectJSONBlock: ((_ objectJSON: [String: Any]) -> [String: Any])?) {
        var filteredObjectDictionary: [String: Any]?

        if let customRelationshipName = relationship.userInfo?[SYNCCustomRemoteKey] as? String {
            filteredObjectDictionary = dictionary[customRelationshipName] as? [String: Any]
        } else if let result = dictionary[relationship.name.hyp_snakeCase()] as? [String: Any] {
            filteredObjectDictionary = result
        } else if let result = dictionary[relationship.name] as? [String: Any] {
            filteredObjectDictionary = result
        }

        if let toOneObjectDictionary = filteredObjectDictionary {
            guard let managedObjectContext = self.managedObjectContext else { return }
            guard let destinationEntity = relationship.destinationEntity else { return }
            guard let entityName = destinationEntity.name else { return }
            guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: managedObjectContext) else { return }

            let localPrimaryKey = toOneObjectDictionary[entity.sync_remotePrimaryKey()]
            let object = managedObjectContext.safeObject(entityName, localPrimaryKey: localPrimaryKey, parent: self, parentRelationshipName: relationship.name) ?? NSEntityDescription.insertNewObject(forEntityName: entityName, into: managedObjectContext)

            object.sync_fill(with: toOneObjectDictionary, parent: self, parentRelationship: relationship, context: context, operations: operations, shouldContinueBlock: shouldContinueBlock, objectJSONBlock: objectJSONBlock)

            let currentRelationship = self.value(forKey: relationship.name)
            if currentRelationship == nil || !(currentRelationship! as AnyObject).isEqual(object) {
                setValue(object, forKey: relationship.name)
            }
        } else {
            let currentRelationship = self.value(forKey: relationship.name)
            if currentRelationship != nil {
                setValue(nil, forKey: relationship.name)
            }
        }
    }
}
