import CoreData
import NSEntityDescription_SYNCPrimaryKey
import NSString_HYPNetworking

public extension NSManagedObjectContext {
    /**
     Safely fetches a NSManagedObject in the current context. If no remoteID is provided then it will check for the parent entity and use that. Otherwise it will return nil.
     - parameter entityName: The name of the Core Data entity.
     - parameter remoteID: The primary key.
     - parameter parent: The parent of the object.
     - parameter parentRelationshipName: The name of the relationship with the parent.
     - returns: A NSManagedObject contained in the provided context.
     */
    public func sync_safeObject(entityName: String, remoteID: AnyObject?, parent: NSManagedObject?, parentRelationshipName: String?) -> NSManagedObject? {
        if let remoteID = remoteID {
            let entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: self)!
            let request = NSFetchRequest(entityName: entityName)
            let localKey = entity.sync_localKey()
            request.predicate = NSPredicate(format: "%K = %@", localKey, (remoteID as! NSObject))
            let objects = try! self.executeFetchRequest(request)
            return objects.first as? NSManagedObject
        } else if let parentRelationshipName = parentRelationshipName {
            // More info: https://github.com/hyperoslo/Sync/pull/72
            return parent?.valueForKey(parentRelationshipName) as? NSManagedObject
        } else {
            return nil
        }
    }
}
