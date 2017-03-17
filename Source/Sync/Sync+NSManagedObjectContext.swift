import CoreData

extension NSManagedObjectContext {
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
        Sync.changes(changes, inEntityNamed: entityName, predicate: nil, parent: nil, parentRelationship: nil, inContext: self, operations: .all, completion: completion)
    }

    public func changes(_ changes: [[String: Any]], inEntityNamed entityName: String, predicate: NSPredicate?, parent: NSManagedObject?, parentRelationship: NSRelationshipDescription?, operations: Sync.OperationOptions, completion: ((_ error: NSError?) -> Void)?) {

        var error: NSError?
        do {
            try Sync.changes(changes, inEntityNamed: entityName, predicate: predicate, parent: parent, parentRelationship: parentRelationship, inContext: self, operations: operations, shouldContinueBlock: nil, objectJSONBlock: nil)
        } catch let syncError as NSError {
            error = syncError
        }

        if TestCheck.isTesting {
            completion?(error)
        } else {
            DispatchQueue.main.async {
                completion?(error)
            }
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
    ///   - parent: The parent of the synced items, useful if you are syncing the childs of an object, for example an Album has many photos, if this photos don't incldue the album's JSON object.
    ///   - completion: The completion block, it returns an error if something in the Sync process goes wrong.
    public func sync(_ changes: [[String: Any]], inEntityNamed entityName: String, predicate: NSPredicate?, parent: NSManagedObject?, completion: ((_ error: NSError?) -> Void)?) {
        Sync.changes(changes, inEntityNamed: entityName, predicate: predicate, parent: parent, parentRelationship: nil, inContext: self, operations: .all, completion: completion)
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
        Sync.verifyContextSafety(context: self)

        return try Sync.fetch(id, inEntityNamed: entityName, using: self)
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
        Sync.verifyContextSafety(context: self)

        return try Sync.insertOrUpdate(changes, inEntityNamed: entityName, using: self)
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
        Sync.verifyContextSafety(context: self)

        return try Sync.update(id, with: changes, inEntityNamed: entityName, using: self)
    }

    /// Deletes a managed object for the provided primary key in an specific entity.
    ///
    /// - Parameters:
    ///   - id: The primary key.
    ///   - entityName: The name of the entity.
    /// - Throws: Core Data related issues.
    public func delete(_ id: Any, inEntityNamed entityName: String) throws {
        Sync.verifyContextSafety(context: self)

        return try Sync.delete(id, inEntityNamed: entityName, using: self)
    }
}

extension Sync {
    /// Syncs the entity using the received array of dictionaries, maps one-to-many, many-to-many and one-to-one relationships.
    /// It also syncs relationships where only the id is present, for example if your model is: Company -> Employee,
    /// and your employee has a company_id, it will try to sync using that ID instead of requiring you to provide the
    /// entire company object inside the employees dictionary.
    ///
    /// - Parameters:
    ///   - changes: The array of dictionaries used in the sync process.
    ///   - entityName: The name of the entity to be synced.
    ///   - context: The Core Data context to be used.
    ///   - completion: The completion block, it returns an error if something in the Sync process goes wrong.
    public class func changes(_ changes: [[String: Any]], inEntityNamed entityName: String, inContext context: NSManagedObjectContext, completion: ((_ error: NSError?) -> Void)?) {
        self.changes(changes, inEntityNamed: entityName, predicate: nil, parent: nil, parentRelationship: nil, inContext: context, operations: .all, completion: completion)
    }

    public class func changes(_ changes: [[String: Any]], inEntityNamed entityName: String, predicate: NSPredicate?, parent: NSManagedObject?, parentRelationship: NSRelationshipDescription?, inContext context: NSManagedObjectContext, operations: Sync.OperationOptions, completion: ((_ error: NSError?) -> Void)?) {

        var error: NSError?
        do {
            try self.changes(changes, inEntityNamed: entityName, predicate: predicate, parent: parent, parentRelationship: parentRelationship, inContext: context, operations: operations, shouldContinueBlock: nil, objectJSONBlock: nil)
        } catch let syncError as NSError {
            error = syncError
        }

        if TestCheck.isTesting {
            completion?(error)
        } else {
            DispatchQueue.main.async {
                completion?(error)
            }
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
     - parameter parent: The parent of the synced items, useful if you are syncing the childs of an object, for example
     an Album has many photos, if this photos don't incldue the album's JSON object, syncing the photos JSON requires
     - parameter context: The context where the items will be created, in general this should be a background context.
     - parameter completion: The completion block, it returns an error if something in the Sync process goes wrong.
     */
    public class func changes(_ changes: [[String: Any]], inEntityNamed entityName: String, predicate: NSPredicate?, parent: NSManagedObject?, inContext context: NSManagedObjectContext, completion: ((_ error: NSError?) -> Void)?) {
        self.changes(changes, inEntityNamed: entityName, predicate: predicate, parent: parent, parentRelationship: nil, inContext: context, operations: .all, completion: completion)
    }
}
