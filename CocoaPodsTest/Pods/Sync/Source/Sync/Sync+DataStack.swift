public extension DataStack {
    /// Syncs the entity using the received array of dictionaries, maps one-to-many, many-to-many and one-to-one relationships.
    /// It also syncs relationships where only the id is present, for example if your model is: Company -> Employee,
    /// and your employee has a company_id, it will try to sync using that ID instead of requiring you to provide the
    /// entire company object inside the employees dictionary.
    ///
    /// - Parameters:
    ///   - changes: The array of dictionaries used in the sync process.
    ///   - entityName: The name of the entity to be synced.
    ///   - completion: The completion block, it returns an error if something in the Sync process goes wrong.
    public func sync(_ changes: [[String: Any]], inEntityNamed entityName: String, completion: ((_ error: NSError?) -> Void)?) {
        Sync.changes(changes, inEntityNamed: entityName, predicate: nil, dataStack: self, operations: .all, completion: completion)
    }

    /// Syncs the entity using the received array of dictionaries, maps one-to-many, many-to-many and one-to-one relationships.
    /// It also syncs relationships where only the id is present, for example if your model is: Company -> Employee,
    /// and your employee has a company_id, it will try to sync using that ID instead of requiring you to provide the
    /// entire company object inside the employees dictionary.
    ///
    /// - Parameters:
    ///   - changes: The array of dictionaries used in the sync process.
    ///   - entityName: The name of the entity to be synced.
    ///   - operations: The type of operations to be applied to the data, Insert, Update, Delete or any possible combination.
    ///   - completion: The completion block, it returns an error if something in the Sync process goes wrong.
    public func sync(_ changes: [[String: Any]], inEntityNamed entityName: String, operations: Sync.OperationOptions, completion: ((_ error: NSError?) -> Void)?) {
        Sync.changes(changes, inEntityNamed: entityName, predicate: nil, dataStack: self, operations: operations, completion: completion)
    }

    /// Syncs the entity using the received array of dictionaries, maps one-to-many, many-to-many and one-to-one relationships.
    /// It also syncs relationships where only the id is present, for example if your model is: Company -> Employee,
    /// and your employee has a company_id, it will try to sync using that ID instead of requiring you to provide the
    /// entire company object inside the employees dictionary.
    ///
    /// - Parameters:
    ///   - changes: The array of dictionaries used in the sync process.
    ///   - entityName: The name of the entity to be synced.
    ///   - predicate: The predicate used to filter out changes, if you want to exclude some local items to be taken in account in the Sync process, you just need to provide this predicate.
    ///   - completion: The completion block, it returns an error if something in the Sync process goes wrong.
    public func sync(_ changes: [[String: Any]], inEntityNamed entityName: String, predicate: NSPredicate?, completion: ((_ error: NSError?) -> Void)?) {
        self.performInNewBackgroundContext { backgroundContext in
            Sync.changes(changes, inEntityNamed: entityName, predicate: predicate, parent: nil, parentRelationship: nil, inContext: backgroundContext, operations: .all, completion: completion)
        }
    }

    /// Syncs the entity using the received array of dictionaries, maps one-to-many, many-to-many and one-to-one relationships.
    /// It also syncs relationships where only the id is present, for example if your model is: Company -> Employee,
    /// and your employee has a company_id, it will try to sync using that ID instead of requiring you to provide the
    /// entire company object inside the employees dictionary.
    ///
    /// - Parameters:
    ///   - changes: The array of dictionaries used in the sync process.
    ///   - entityName: The name of the entity to be synced.
    ///   - predicate: The predicate used to filter out changes, if you want to exclude some local items to be taken in account in the Sync process, you just need to provide this predicate.
    ///   - operations: The type of operations to be applied to the data, Insert, Update, Delete or any possible combination.
    ///   - completion: The completion block, it returns an error if something in the Sync process goes wrong.
    public func sync(_ changes: [[String: Any]], inEntityNamed entityName: String, predicate: NSPredicate?, operations: Sync.OperationOptions, completion: ((_ error: NSError?) -> Void)?) {
        self.performInNewBackgroundContext { backgroundContext in
            Sync.changes(changes, inEntityNamed: entityName, predicate: predicate, parent: nil, parentRelationship: nil, inContext: backgroundContext, operations: operations, completion: completion)
        }
    }

    /// Syncs the entity using the received array of dictionaries, maps one-to-many, many-to-many and one-to-one relationships.
    /// It also syncs relationships where only the id is present, for example if your model is: Company -> Employee,
    /// and your employee has a company_id, it will try to sync using that ID instead of requiring you to provide the
    /// entire company object inside the employees dictionary.
    ///
    /// - Parameters:
    ///   - changes: The array of dictionaries used in the sync process.
    ///   - entityName: The name of the entity to be synced.
    ///   - parent: The parent of the synced items, useful if you are syncing the childs of an object, for example
    /// an Album has many photos, if this photos don't incldue the album's JSON object, syncing the photos JSON requires
    /// you to send the parent album to do the proper mapping.
    ///   - completion: The completion block, it returns an error if something in the Sync process goes wrong.
    public func sync(_ changes: [[String: Any]], inEntityNamed entityName: String, parent: NSManagedObject, completion: ((_ error: NSError?) -> Void)?) {
        self.performInNewBackgroundContext { backgroundContext in
            let safeParent = parent.sync_copyInContext(backgroundContext)
            guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: backgroundContext) else { fatalError("Couldn't find entity named: \(entityName)") }
            let relationships = entity.relationships(forDestination: parent.entity)
            var predicate: NSPredicate?
            let firstRelationship = relationships.first

            if let firstRelationship = firstRelationship {
                predicate = NSPredicate(format: "%K = %@", firstRelationship.name, safeParent)
            }
            Sync.changes(changes, inEntityNamed: entityName, predicate: predicate, parent: safeParent, parentRelationship: firstRelationship?.inverseRelationship, inContext: backgroundContext, operations: .all, completion: completion)
        }
    }

    /// Fetches a managed object for the provided primary key in an specific entity.
    ///
    /// - Parameters:
    ///   - id: The primary key.
    ///   - entityName: The name of the entity.
    /// - Returns: A managed object for a provided primary key in an specific entity.
    /// - Throws: Core Data related issues.
    @discardableResult
    public func fetch<ResultType: NSManagedObject>(_ id: Any, inEntityNamed entityName: String) throws -> ResultType? {
        Sync.verifyContextSafety(context: self.mainContext)

        return try Sync.fetch(id, inEntityNamed: entityName, using: self.mainContext)
    }

    /// Inserts or updates an object using the given changes dictionary in an specific entity.
    ///
    /// - Parameters:
    ///   - changes: The dictionary to be used to update or create the object.
    ///   - entityName: The name of the entity.
    /// - Returns: The inserted or updated object. If you call this method from a background context, make sure to not use this on the main thread.
    /// - Throws: Core Data related issues.
    @discardableResult
    public func insertOrUpdate<ResultType: NSManagedObject>(_ changes: [String: Any], inEntityNamed entityName: String) throws -> ResultType {
        Sync.verifyContextSafety(context: self.mainContext)

        return try Sync.insertOrUpdate(changes, inEntityNamed: entityName, using: self.mainContext)
    }

    /// Updates an object using the given changes dictionary for the provided primary key in an specific entity.
    ///
    /// - Parameters:
    ///   - id: The primary key.
    ///   - changes: The dictionary to be used to update the object.
    ///   - entityName: The name of the entity.
    /// - Returns: The updated object, if not found it returns nil. If you call this method from a background context, make sure to not use this on the main thread.
    /// - Throws: Core Data related issues.
    @discardableResult
    public func update<ResultType: NSManagedObject>(_ id: Any, with changes: [String: Any], inEntityNamed entityName: String) throws -> ResultType? {
        Sync.verifyContextSafety(context: self.mainContext)

        return try Sync.update(id, with: changes, inEntityNamed: entityName, using: self.mainContext)
    }

    /// Deletes a managed object for the provided primary key in an specific entity.
    ///
    /// - Parameters:
    ///   - id: The primary key.
    ///   - entityName: The name of the entity.
    /// - Throws: Core Data related issues.
    public func delete(_ id: Any, inEntityNamed entityName: String) throws {
        Sync.verifyContextSafety(context: self.mainContext)

        return try Sync.delete(id, inEntityNamed: entityName, using: self.mainContext)
    }
}

public extension Sync {
    /**
     Syncs the entity using the received array of dictionaries, maps one-to-many, many-to-many and one-to-one relationships.
     It also syncs relationships where only the id is present, for example if your model is: Company -> Employee,
     and your employee has a company_id, it will try to sync using that ID instead of requiring you to provide the
     entire company object inside the employees dictionary.
     - parameter changes: The array of dictionaries used in the sync process.
     - parameter entityName: The name of the entity to be synced.
     - parameter dataStack: The DataStack instance.
     - parameter completion: The completion block, it returns an error if something in the Sync process goes wrong.
     */
    public class func changes(_ changes: [[String: Any]], inEntityNamed entityName: String, dataStack: DataStack, completion: ((_ error: NSError?) -> Void)?) {
        self.changes(changes, inEntityNamed: entityName, predicate: nil, dataStack: dataStack, operations: .all, completion: completion)
    }

    /**
     Syncs the entity using the received array of dictionaries, maps one-to-many, many-to-many and one-to-one relationships.
     It also syncs relationships where only the id is present, for example if your model is: Company -> Employee,
     and your employee has a company_id, it will try to sync using that ID instead of requiring you to provide the
     entire company object inside the employees dictionary.
     - parameter changes: The array of dictionaries used in the sync process.
     - parameter entityName: The name of the entity to be synced.
     - parameter dataStack: The DataStack instance.
     - parameter operations: The type of operations to be applied to the data, Insert, Update, Delete or any possible combination.
     - parameter completion: The completion block, it returns an error if something in the Sync process goes wrong.
     */
    public class func changes(_ changes: [[String: Any]], inEntityNamed entityName: String, dataStack: DataStack, operations: Sync.OperationOptions, completion: ((_ error: NSError?) -> Void)?) {
        self.changes(changes, inEntityNamed: entityName, predicate: nil, dataStack: dataStack, operations: operations, completion: completion)
    }

    /**
     Syncs the entity using the received array of dictionaries, maps one-to-many, many-to-many and one-to-one relationships.
     It also syncs relationships where only the id is present, for example if your model is: Company -> Employee,
     and your employee has a company_id, it will try to sync using that ID instead of requiring you to provide the
     entire company object inside the employees dictionary.
     - parameter changes: The array of dictionaries used in the sync process.
     - parameter entityName: The name of the entity to be synced.
     - parameter predicate: The predicate used to filter out changes, if you want to exclude some local items to be taken in
     account in the Sync process, you just need to provide this predicate.
     - parameter dataStack: The DataStack instance.
     - parameter completion: The completion block, it returns an error if something in the Sync process goes wrong.
     */
    public class func changes(_ changes: [[String: Any]], inEntityNamed entityName: String, predicate: NSPredicate?, dataStack: DataStack, completion: ((_ error: NSError?) -> Void)?) {
        dataStack.performInNewBackgroundContext { backgroundContext in
            self.changes(changes, inEntityNamed: entityName, predicate: predicate, parent: nil, parentRelationship: nil, inContext: backgroundContext, operations: .all, completion: completion)
        }
    }

    /**
     Syncs the entity using the received array of dictionaries, maps one-to-many, many-to-many and one-to-one relationships.
     It also syncs relationships where only the id is present, for example if your model is: Company -> Employee,
     and your employee has a company_id, it will try to sync using that ID instead of requiring you to provide the
     entire company object inside the employees dictionary.
     - parameter changes: The array of dictionaries used in the sync process.
     - parameter entityName: The name of the entity to be synced.
     - parameter predicate: The predicate used to filter out changes, if you want to exclude some local items to be taken in
     account in the Sync process, you just need to provide this predicate.
     - parameter dataStack: The DataStack instance.
     - parameter operations: The type of operations to be applied to the data, Insert, Update, Delete or any possible combination.
     - parameter completion: The completion block, it returns an error if something in the Sync process goes wrong.
     */
    public class func changes(_ changes: [[String: Any]], inEntityNamed entityName: String, predicate: NSPredicate?, dataStack: DataStack, operations: Sync.OperationOptions, completion: ((_ error: NSError?) -> Void)?) {
        dataStack.performInNewBackgroundContext { backgroundContext in
            self.changes(changes, inEntityNamed: entityName, predicate: predicate, parent: nil, parentRelationship: nil, inContext: backgroundContext, operations: operations, completion: completion)
        }
    }

    /**
     Syncs the entity using the received array of dictionaries, maps one-to-many, many-to-many and one-to-one relationships.
     It also syncs relationships where only the id is present, for example if your model is: Company -> Employee,
     and your employee has a company_id, it will try to sync using that ID instead of requiring you to provide the
     entire company object inside the employees dictionary.
     - parameter changes: The array of dictionaries used in the sync process.
     - parameter entityName: The name of the entity to be synced.
     - parameter parent: The parent of the synced items, useful if you are syncing the childs of an object, for example
     an Album has many photos, if this photos don't incldue the album's JSON object, syncing the photos JSON requires
     you to send the parent album to do the proper mapping.
     - parameter dataStack: The DataStack instance.
     - parameter completion: The completion block, it returns an error if something in the Sync process goes wrong.
     */
    public class func changes(_ changes: [[String: Any]], inEntityNamed entityName: String, parent: NSManagedObject, dataStack: DataStack, completion: ((_ error: NSError?) -> Void)?) {
        dataStack.performInNewBackgroundContext { backgroundContext in
            let safeParent = parent.sync_copyInContext(backgroundContext)
            guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: backgroundContext) else { fatalError("Couldn't find entity named: \(entityName)") }
            let relationships = entity.relationships(forDestination: parent.entity)
            var predicate: NSPredicate?
            let firstRelationship = relationships.first

            if let firstRelationship = firstRelationship {
                predicate = NSPredicate(format: "%K = %@", firstRelationship.name, safeParent)
            }
            self.changes(changes, inEntityNamed: entityName, predicate: predicate, parent: safeParent, parentRelationship: firstRelationship?.inverseRelationship, inContext: backgroundContext, operations: .all, completion: completion)
        }
    }
}
