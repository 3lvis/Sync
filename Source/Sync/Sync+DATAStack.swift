import DATAStack

public extension Sync {
    /**
     Syncs the entity using the received array of dictionaries, maps one-to-many, many-to-many and one-to-one relationships.
     It also syncs relationships where only the id is present, for example if your model is: Company -> Employee,
     and your employee has a company_id, it will try to sync using that ID instead of requiring you to provide the
     entire company object inside the employees dictionary.
     - parameter changes: The array of dictionaries used in the sync process.
     - parameter entityName: The name of the entity to be synced.
     - parameter dataStack: The DATAStack instance.
     - parameter completion: The completion block, it returns an error if something in the Sync process goes wrong.
     */
    public class func changes(_ changes: [[String: Any]], inEntityNamed entityName: String, dataStack: DATAStack, completion: ((_ error: NSError?) -> Void)?) {
        self.changes(changes, inEntityNamed: entityName, predicate: nil, dataStack: dataStack, operations: .All, completion: completion)
    }

    /**
     Syncs the entity using the received array of dictionaries, maps one-to-many, many-to-many and one-to-one relationships.
     It also syncs relationships where only the id is present, for example if your model is: Company -> Employee,
     and your employee has a company_id, it will try to sync using that ID instead of requiring you to provide the
     entire company object inside the employees dictionary.
     - parameter changes: The array of dictionaries used in the sync process.
     - parameter entityName: The name of the entity to be synced.
     - parameter dataStack: The DATAStack instance.
     - parameter operations: The type of operations to be applied to the data, Insert, Update, Delete or any possible combination.
     - parameter completion: The completion block, it returns an error if something in the Sync process goes wrong.
     */
    public class func changes(_ changes: [[String: Any]], inEntityNamed entityName: String, dataStack: DATAStack, operations: Sync.OperationOptions, completion: ((_ error: NSError?) -> Void)?) {
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
     - parameter dataStack: The DATAStack instance.
     - parameter completion: The completion block, it returns an error if something in the Sync process goes wrong.
     */
    public class func changes(_ changes: [[String: Any]], inEntityNamed entityName: String, predicate: NSPredicate?, dataStack: DATAStack, completion: ((_ error: NSError?) -> Void)?) {
        dataStack.performInNewBackgroundContext { backgroundContext in
            self.changes(changes, inEntityNamed: entityName, predicate: predicate, parent: nil, parentRelationship: nil, inContext: backgroundContext, operations: .All, completion: completion)
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
     - parameter dataStack: The DATAStack instance.
     - parameter operations: The type of operations to be applied to the data, Insert, Update, Delete or any possible combination.
     - parameter completion: The completion block, it returns an error if something in the Sync process goes wrong.
     */
    public class func changes(_ changes: [[String: Any]], inEntityNamed entityName: String, predicate: NSPredicate?, dataStack: DATAStack, operations: Sync.OperationOptions, completion: ((_ error: NSError?) -> Void)?) {
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
     - parameter dataStack: The DATAStack instance.
     - parameter completion: The completion block, it returns an error if something in the Sync process goes wrong.
     */
    public class func changes(_ changes: [[String: Any]], inEntityNamed entityName: String, parent: NSManagedObject, dataStack: DATAStack, completion: ((_ error: NSError?) -> Void)?) {
        dataStack.performInNewBackgroundContext { backgroundContext in
            let safeParent = parent.sync_copyInContext(backgroundContext)
            guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: backgroundContext) else { fatalError("Couldn't find entity named: \(entityName)") }
            let relationships = entity.relationships(forDestination: parent.entity)
            var predicate: NSPredicate?
            let firstRelationship = relationships.first

            if let firstRelationship = firstRelationship {
                predicate = NSPredicate(format: "%K = %@", firstRelationship.name, safeParent)
            }
            self.changes(changes, inEntityNamed: entityName, predicate: predicate, parent: safeParent, parentRelationship: firstRelationship?.inverseRelationship, inContext: backgroundContext, operations: .All, completion: completion)
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
        self.changes(changes, inEntityNamed: entityName, predicate: predicate, parent: parent, parentRelationship: nil, inContext: context, operations: .All, completion: completion)
    }
}
