import CoreData

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
    public class func changes(_ changes: [[String : Any]], inEntityNamed entityName: String, predicate: NSPredicate?, persistentContainer: NSPersistentContainer, completion: ((_ error: NSError?) -> Void)?) {
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
    public class func changes(_ changes: [[String : Any]], inEntityNamed entityName: String, predicate: NSPredicate?, persistentContainer: NSPersistentContainer, operations: Sync.OperationOptions, completion: ((_ error: NSError?) -> Void)?) {
        persistentContainer.performBackgroundTask { backgroundContext in
            self.changes(changes, inEntityNamed: entityName, predicate: predicate, parent: nil, parentRelationship: nil, inContext: backgroundContext, operations: operations, completion: completion)
        }
    }
}
