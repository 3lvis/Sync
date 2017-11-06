extension Sync {
    /// Fetches a managed object for the provided primary key in an specific entity.
    ///
    /// - Parameters:
    ///   - id: The primary key.
    ///   - entityName: The name of the entity.
    ///   - context: The context to be used, make sure that this method gets called in the same thread as the context using `perform` or `performAndWait`.
    /// - Returns: A managed object for a provided primary key in an specific entity.
    /// - Throws: Core Data related issues.
    @discardableResult
    public class func fetch<ResultType: NSManagedObject>(_ id: Any, inEntityNamed entityName: String, using context: NSManagedObjectContext) throws -> ResultType? {
        Sync.verifyContextSafety(context: context)

        guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else { abort() }
        let localPrimaryKey = entity.sync_localPrimaryKey()
        let fetchRequest = NSFetchRequest<ResultType>(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "%K = %@", localPrimaryKey, id as! NSObject)

        let objects = try context.fetch(fetchRequest)

        return objects.first
    }

    /// Inserts or updates an object using the given changes dictionary in an specific entity.
    ///
    /// - Parameters:
    ///   - changes: The dictionary to be used to update or create the object.
    ///   - entityName: The name of the entity.
    ///   - context: The context to be used, make sure that this method gets called in the same thread as the context using `perform` or `performAndWait`.
    /// - Returns: The inserted or updated object. If you call this method from a background context, make sure to not use this on the main thread.
    /// - Throws: Core Data related issues.
    @discardableResult
    public class func insertOrUpdate<ResultType: NSManagedObject>(_ changes: [String: Any], inEntityNamed entityName: String, using context: NSManagedObjectContext) throws -> ResultType {
        Sync.verifyContextSafety(context: context)

        guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else { abort() }
        let localPrimaryKey = entity.sync_localPrimaryKey()
        let remotePrimaryKey = entity.sync_remotePrimaryKey()
        guard let id = changes[remotePrimaryKey] as? NSObject else { fatalError("Couldn't find primary key \(remotePrimaryKey) in JSON for object in entity \(entityName)") }
        let fetchRequest = NSFetchRequest<ResultType>(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "%K = %@", localPrimaryKey, id)

        let fetchedObjects = try context.fetch(fetchRequest)
        let insertedOrUpdatedObjects: [ResultType]
        if fetchedObjects.count > 0 {
            insertedOrUpdatedObjects = fetchedObjects
        } else {
            let inserted = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context) as! ResultType
            insertedOrUpdatedObjects = [inserted]
        }

        for object in insertedOrUpdatedObjects {
            object.sync_fill(with: changes, parent: nil, parentRelationship: nil, context: context, operations: [.all], shouldContinueBlock: nil, objectJSONBlock: nil)
        }

        if context.hasChanges {
            try context.save()
        }

        return insertedOrUpdatedObjects.first!
    }

    /// Updates an object using the given changes dictionary for the provided primary key in an specific entity.
    ///
    /// - Parameters:
    ///   - id: The primary key.
    ///   - changes: The dictionary to be used to update the object.
    ///   - entityName: The name of the entity.
    ///   - context: The context to be used, make sure that this method gets called in the same thread as the context using `perform` or `performAndWait`.
    /// - Returns: The updated object, if not found it returns nil. If you call this method from a background context, make sure to not use this on the main thread.
    /// - Throws: Core Data related issues.
    @discardableResult
    public class func update<ResultType: NSManagedObject>(_ id: Any, with changes: [String: Any], inEntityNamed entityName: String, using context: NSManagedObjectContext) throws -> ResultType? {
        Sync.verifyContextSafety(context: context)

        guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else { fatalError("Couldn't find an entity named \(entityName)") }
        let localPrimaryKey = entity.sync_localPrimaryKey()
        let fetchRequest = NSFetchRequest<ResultType>(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "%K = %@", localPrimaryKey, id as! NSObject)

        let objects = try context.fetch(fetchRequest)
        for updated in objects {
            updated.sync_fill(with: changes, parent: nil, parentRelationship: nil, context: context, operations: [.all], shouldContinueBlock: nil, objectJSONBlock: nil)
        }

        if context.hasChanges {
            try context.save()
        }

        return objects.first
    }

    /// Deletes a managed object for the provided primary key in an specific entity.
    ///
    /// - Parameters:
    ///   - id: The primary key.
    ///   - entityName: The name of the entity.
    ///   - context: The context to be used, make sure that this method gets called in the same thread as the context using `perform` or `performAndWait`.
    /// - Throws: Core Data related issues.
    public class func delete(_ id: Any, inEntityNamed entityName: String, using context: NSManagedObjectContext) throws {
        Sync.verifyContextSafety(context: context)

        guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else { abort() }
        let localPrimaryKey = entity.sync_localPrimaryKey()
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "%K = %@", localPrimaryKey, id as! NSObject)

        let objects = try context.fetch(fetchRequest)
        guard objects.count > 0 else { return }

        for deletedObject in objects {
            context.delete(deletedObject)
        }
        
        if context.hasChanges {
            try context.save()
        }
    }
}
