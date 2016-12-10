import CoreData

@available(iOS 10, watchOS 3, tvOS 10, OSX 10.12, *)
public extension NSPersistentContainer {
    /**
     Syncs the entity using the received array of dictionaries, maps one-to-many, many-to-many and one-to-one relationships.
     It also syncs relationships where only the id is present, for example if your model is: Company -> Employee,
     and your employee has a company_id, it will try to sync using that ID instead of requiring you to provide the
     entire company object inside the employees dictionary.
     - parameter changes: The array of dictionaries used in the sync process.
     - parameter entityName: The name of the entity to be synced.
     - parameter completion: The completion block, it returns an error if something in the Sync process goes wrong.
     */
    @available(iOS 10, watchOS 3, tvOS 10, OSX 10.12, *)
    public func sync(_ changes: [[String: Any]], inEntityNamed entityName: String, completion: ((_ error: NSError?) -> Void)?) {
        self.sync(changes, inEntityNamed: entityName, predicate: nil, parent: nil, parentRelationship: nil, operations: .All, completion: completion)
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
     - parameter persistentContainer: The NSPersistentContainer instance.
     - parameter operations: The type of operations to be applied to the data, Insert, Update, Delete or any possible combination.
     - parameter completion: The completion block, it returns an error if something in the Sync process goes wrong.
     */
    @available(iOS 10, watchOS 3, tvOS 10, OSX 10.12, *)
    public func sync(_ changes: [[String: Any]], inEntityNamed entityName: String, predicate: NSPredicate?, parent: NSManagedObject?, parentRelationship: NSRelationshipDescription?, operations: Sync.OperationOptions, completion: ((_ error: NSError?) -> Void)?) {
        self.performBackgroundTask { backgroundContext in
            Sync.changes(changes, inEntityNamed: entityName, predicate: predicate, parent: parent, parentRelationship: parentRelationship, inContext: backgroundContext, operations: operations, completion: completion)
        }
    }

    /// Inserts or updates an object using the given changes dictionary in an specific entity.
    ///
    /// - Parameters:
    ///   - changes: The dictionary to be used to update or create the object.
    ///   - entityName: The name of the entity.
    ///   - id: The primary key.
    ///   - error: The Core Data error.
    @available(iOS 10, watchOS 3, tvOS 10, OSX 10.12, *)
    public func insertOrUpdate(_ changes: [String: Any], inEntityNamed entityName: String, completion: @escaping (_ result: Result<Any>) -> Void) {
        self.performBackgroundTask { backgroundContext in
            do {
                let result = try Sync.insertOrUpdate(changes, inEntityNamed: entityName, using: backgroundContext)
                let localPrimaryKey = result.entity.sync_localPrimaryKey()
                let id = result.value(forKey: localPrimaryKey)
                DispatchQueue.main.async {
                    completion(Result.success(id!))
                }
            } catch let error as NSError {
                DispatchQueue.main.async {
                    completion(Result.failure(error))
                }
            }
        }
    }

    /// Updates an object using the given changes dictionary for the provided primary key in an specific entity.
    ///
    /// - Parameters:
    ///   - id: The primary key.
    ///   - changes: The dictionary to be used to update the object.
    ///   - entityName: The name of the entity.
    ///   - error: The Core Data error.
    @available(iOS 10, watchOS 3, tvOS 10, OSX 10.12, *)
    public func update(_ id: Any, with changes: [String: Any], inEntityNamed entityName: String, completion: @escaping (_ result: Result<Any>) -> Void) {
        self.performBackgroundTask { backgroundContext in
            do {
                var updatedID: Any?
                if let result = try Sync.update(id, with: changes, inEntityNamed: entityName, using: backgroundContext) {
                    let localPrimaryKey = result.entity.sync_localPrimaryKey()
                    updatedID = result.value(forKey: localPrimaryKey)
                }
                DispatchQueue.main.async {
                    completion(Result.success(updatedID!))
                }
            } catch let error as NSError {
                DispatchQueue.main.async {
                    completion(Result.failure(error))
                }
            }
        }
    }

    /// Deletes a managed object for the provided primary key in an specific entity.
    ///
    /// - Parameters:
    ///   - id: The primary key.
    ///   - entityName: The name of the entity.
    ///   - error: The Core Data error.
    @available(iOS 10, watchOS 3, tvOS 10, OSX 10.12, *)
    public func delete(_ id: Any, inEntityNamed entityName: String, completion: @escaping (_ error: NSError?) -> Void) {
        self.performBackgroundTask { backgroundContext in
            do {
                try Sync.delete(id, inEntityNamed: entityName, using: backgroundContext)
                DispatchQueue.main.async {
                    completion(nil)
                }
            } catch let error as NSError {
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        }
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
     - parameter predicate: The predicate used to filter out changes, if you want to exclude some local items to be taken in
     account in the Sync process, you just need to provide this predicate.
     - parameter persistentContainer: The NSPersistentContainer instance.
     - parameter completion: The completion block, it returns an error if something in the Sync process goes wrong.
     */
    @available(iOS 10, watchOS 3, tvOS 10, OSX 10.12, *)
    public class func changes(_ changes: [[String: Any]], inEntityNamed entityName: String, predicate: NSPredicate?, persistentContainer: NSPersistentContainer, completion: ((_ error: NSError?) -> Void)?) {
        self.changes(changes, inEntityNamed: entityName, predicate: predicate, persistentContainer: persistentContainer, operations: .All, completion: completion)
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
     - parameter persistentContainer: The NSPersistentContainer instance.
     - parameter operations: The type of operations to be applied to the data, Insert, Update, Delete or any possible combination.
     - parameter completion: The completion block, it returns an error if something in the Sync process goes wrong.
     */
    @available(iOS 10, watchOS 3, tvOS 10, OSX 10.12, *)
    public class func changes(_ changes: [[String: Any]], inEntityNamed entityName: String, predicate: NSPredicate?, persistentContainer: NSPersistentContainer, operations: Sync.OperationOptions, completion: ((_ error: NSError?) -> Void)?) {
        persistentContainer.performBackgroundTask { backgroundContext in
            self.changes(changes, inEntityNamed: entityName, predicate: predicate, parent: nil, parentRelationship: nil, inContext: backgroundContext, operations: operations, completion: completion)
        }
    }
}
