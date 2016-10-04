import CoreData

public extension NSManagedObjectContext {
    /**
     Safely fetches a NSManagedObject in the current context. If no localPrimaryKey is provided then it will check for the parent entity and use that. Otherwise it will return nil.
     - parameter entityName: The name of the Core Data entity.
     - parameter localPrimaryKey: The primary key.
     - parameter parent: The parent of the object.
     - parameter parentRelationshipName: The name of the relationship with the parent.
     - returns: A NSManagedObject contained in the provided context.
     */
    public func sync_safeObject(_ entityName: String, localPrimaryKey: Any?, parent: NSManagedObject?, parentRelationshipName: String?) -> NSManagedObject? {
        var result: NSManagedObject?

        if let localPrimaryKey = localPrimaryKey as? NSObject, let entity = NSEntityDescription.entity(forEntityName: entityName, in: self) {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            request.predicate = NSPredicate(format: "%K = %@", entity.sync_localPrimaryKey(), localPrimaryKey)
            do {
                let objects = try fetch(request)
                result = objects.first as? NSManagedObject
            } catch {
                fatalError("Failed to fetch request for entityName: \(entityName), predicate: \(request.predicate)")
            }
        } else if let parentRelationshipName = parentRelationshipName {
            // More info: https://github.com/SyncDB/Sync/pull/72
            result = parent?.value(forKey: parentRelationshipName) as? NSManagedObject
        }

        return result
    }
}
