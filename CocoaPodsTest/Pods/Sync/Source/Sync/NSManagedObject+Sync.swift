import CoreData


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
        guard let copiedObject = context.safeObject(entityName, localPrimaryKey: localPrimaryKey, parent: nil, parentRelationshipName: nil) else { fatalError("Couldn't fetch a safe object from entityName: \(entityName) localPrimaryKey: \(String(describing: localPrimaryKey))") }

        return copiedObject
    }

    /**
     Syncs the entity using the received dictionary, maps one-to-many, many-to-many and one-to-one relationships.
     It also syncs relationships where only the id is present, for example if your model is: Company -> Employee,
     and your employee has a company_id, it will try to sync using that ID instead of requiring you to provide the
     entire company object inside the employees dictionary.
     - parameter dictionary: The JSON with the changes to be applied to the entity.
     - parameter parent: The parent of the entity, optional since many entities are orphans.
     - parameter dataStack: The DataStack instance.
     */
    func sync_fill(with dictionary: [String: Any], parent: NSManagedObject?, parentRelationship: NSRelationshipDescription?, context: NSManagedObjectContext, operations: Sync.OperationOptions, shouldContinueBlock: (() -> Bool)?, objectJSONBlock: ((_ objectJSON: [String: Any]) -> [String: Any])?) {
        hyp_fill(with: dictionary)

        for relationship in entity.sync_relationships() {
            let suffix = relationship.isToMany ? "_ids" : "_id"
            let constructedKeyName = relationship.name.hyp_snakeCase() + suffix
            let keyName = relationship.customKey ?? constructedKeyName

            if relationship.isToMany {
                var children: Any?
                if keyName.contains(".") {
                    if let deepMappingRootkey = keyName.components(separatedBy: ".").first {
                        if let rootObject = dictionary[deepMappingRootkey] as? [String: Any] {
                            if let deepMappingLeaveKey = keyName.components(separatedBy: ".").last {
                                children = rootObject[deepMappingLeaveKey]
                            }
                        }
                    }
                } else {
                    children = dictionary[keyName]
                }

                if let localPrimaryKey = children, localPrimaryKey is Array < String> || localPrimaryKey is Array < Int> || localPrimaryKey is NSNull {
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

                var child: Any?
                if keyName.contains(".") {
                    if let deepMappingRootkey = keyName.components(separatedBy: ".").first {
                        if let rootObject = dictionary[deepMappingRootkey] as? [String: Any] {
                            if let deepMappingLeaveKey = keyName.components(separatedBy: ".").last {
                                child = rootObject[deepMappingLeaveKey]
                            }
                        }
                    }
                } else {
                    child = dictionary[keyName]
                }

                if let parent = parent, parentRelationshipIsTheSameAsCurrentRelationship || destinationIsParentSuperEntity {
                    let currentValueForRelationship = self.value(forKey: relationship.name)
                    let newParentIsDifferentThanCurrentValue = parent.isEqual(currentValueForRelationship) == false
                    if newParentIsDifferentThanCurrentValue {
                        self.setValue(parent, forKey: relationship.name)
                    }
                } else if let localPrimaryKey = child, localPrimaryKey is NSString || localPrimaryKey is NSNumber || localPrimaryKey is NSNull {
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

    /// Syncs the entity's to-many relationship, it will also sync the childs of this relationship.
    ///
    /// - Parameters:
    ///   - relationship: The relationship to be synced.
    ///   - dictionary: The JSON with the changes to be applied to the entity.
    ///   - parent: The parent of the entity, optional since many entities are orphans.
    ///   - parentRelationship: The relationship from which the parent was referenced.
    ///   - context: The NSManagedContext involving the current Core Data operation.
    ///   - operations: The Sync.Operation options to be used for this operation.
    ///   - shouldContinueBlock: A block that checks wheter the Sync process should continue to the next element or stop. This is used in conjunction to operations, if the operation is cancelled the Sync process will stop.
    ///   - objectJSONBlock: A block that gives the oportunity to the called to act on the current processed JSON.
    /// - Throws: An exception that will throw if any of the underlaying operations fail.
    func sync_toManyRelationship(_ relationship: NSRelationshipDescription, dictionary: [String: Any], parent: NSManagedObject?, parentRelationship: NSRelationshipDescription?, context: NSManagedObjectContext, operations: Sync.OperationOptions, shouldContinueBlock: (() -> Bool)?, objectJSONBlock: ((_ objectJSON: [String: Any]) -> [String: Any])?) throws {
        let updatedOperations = operations.relationshipOperations()

        var children: [[String: Any]]?
        let childrenIsNull = (relationship.customKey as Any?) is NSNull || dictionary[relationship.name.hyp_snakeCase()] is NSNull || dictionary[relationship.name] is NSNull
        if childrenIsNull {
            children = [[String: Any]]()

            if value(forKey: relationship.name) != nil {
                setValue(nil, forKey: relationship.name)
            }
        } else {
            if let customRelationshipName = relationship.customKey {
                if customRelationshipName.contains(".") {
                    if let deepMappingRootKey = customRelationshipName.components(separatedBy: ".").first {
                        if let rootObject = dictionary[deepMappingRootKey] as? [String: Any] {
                            if let deepMappingLeaveKey = customRelationshipName.components(separatedBy: ".").last {
                                children = rootObject[deepMappingLeaveKey] as? [[String: Any]]
                            }
                        }
                    }
                } else {
                    children = dictionary[customRelationshipName] as? [[String: Any]]
                }
            } else if let result = dictionary[relationship.name.hyp_snakeCase()] as? [[String: Any]] {
                children = result
            } else if let result = dictionary[relationship.name] as? [[String: Any]] {
                children = result
            }
        }

        let inverseIsToMany = relationship.inverseRelationship?.isToMany ?? false
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
                        safeLocalObjects = try context.fetch(request) as? [NSManagedObject] ?? [NSManagedObject]()
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
                            objects = try context.fetch(request) as? [NSManagedObject] ?? [NSManagedObject]()
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
            var childOperations = updatedOperations
            let childrenIDs = (((childIDs as Any) as AnyObject) as? NSArray) ?? NSArray()

            if manyToMany {
                childOperations.remove(.delete)
            }

            if let entity = NSEntityDescription.entity(forEntityName: childEntityName, in: context) {
                if manyToMany {
                    childPredicate = NSPredicate(format: "ANY %K IN %@", entity.sync_localPrimaryKey(), childrenIDs)
                } else {
                    guard let inverseEntityName = relationship.inverseRelationship?.name else { fatalError() }
                    let primaryKeyAttribute = entity.sync_primaryKeyAttribute()

                    // Required in order to convert the JSON IDs into the same type as the ones Core Data expects. If the local primary key
                    // is of type Date, then we need to convert the array of strings in the JSON to be an array of dates.
                    // More info: https://github.com/3lvis/Sync/pull/477
                    let ids = childrenIDs.compactMap { value(forAttributeDescription: primaryKeyAttribute, usingRemoteValue: $0) }
                    childPredicate = NSPredicate(format: "ANY %K IN %@ OR %K = %@", entity.sync_localPrimaryKey(), ids, inverseEntityName, self)
                }
            }

            try Sync.changes(children, inEntityNamed: childEntityName, predicate: childPredicate, parent: self, parentRelationship: relationship, inContext: context, operations: childOperations, shouldContinueBlock: shouldContinueBlock, objectJSONBlock: objectJSONBlock)
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
     - parameter dataStack: The DataStack instance.
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
     - parameter dataStack: The DataStack instance.
     */
    func sync_toOneRelationship(_ relationship: NSRelationshipDescription, dictionary: [String: Any], context: NSManagedObjectContext, operations: Sync.OperationOptions, shouldContinueBlock: (() -> Bool)?, objectJSONBlock: ((_ objectJSON: [String: Any]) -> [String: Any])?) {
        var filteredObjectDictionary: [String: Any]?
        var jsonContainsRelationship = false

        if let customRelationshipName = relationship.customKey {
            if customRelationshipName.contains(".") {
                if let deepMappingRootKey = customRelationshipName.components(separatedBy: ".").first {
                    if let rootObject = dictionary[deepMappingRootKey] as? [String: Any] {
                        if let deepMappingLeaveKey = customRelationshipName.components(separatedBy: ".").last {
                            filteredObjectDictionary = rootObject[deepMappingLeaveKey] as? [String: Any]
                            jsonContainsRelationship = rootObject[deepMappingLeaveKey] != nil
                        }
                    }
                }
            } else {
                filteredObjectDictionary = dictionary[customRelationshipName] as? [String: Any]
                jsonContainsRelationship = dictionary[customRelationshipName] != nil
            }
        } else if let result = dictionary[relationship.name.hyp_snakeCase()] as? [String: Any] {
            filteredObjectDictionary = result
        } else if let result = dictionary[relationship.name] as? [String: Any] {
            filteredObjectDictionary = result
        }

        // Check if the JSON contains key, so we know if we should delete null values
        if !jsonContainsRelationship {
            jsonContainsRelationship = dictionary[relationship.name.hyp_snakeCase()] != nil || dictionary[relationship.name] != nil
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
        } else if jsonContainsRelationship {
            let currentRelationship = self.value(forKey: relationship.name)
            if currentRelationship != nil {
                setValue(nil, forKey: relationship.name)
            }
        }
    }
}
