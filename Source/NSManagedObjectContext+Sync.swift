import CoreData
import NSEntityDescription_SYNCPrimaryKey
import NSString_HYPNetworking

public extension NSManagedObjectContext {
  /**
   Safely fetches a NSManagedObject in the current context. If no localPrimaryKey is provided then it will check for the parent entity and use that. Otherwise it will return nil.
   - parameter entityName: The name of the Core Data entity.
   - parameter localPrimaryKey: The primary key.
   - parameter parent: The parent of the object.
   - parameter parentRelationshipName: The name of the relationship with the parent.
   - returns: A NSManagedObject contained in the provided context.
   */
  public func sync_safeObject(entityName: String, localPrimaryKey: AnyObject?, parent: NSManagedObject?, parentRelationshipName: String?) -> NSManagedObject? {
    if let localPrimaryKey = localPrimaryKey as? NSObject, entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: self) {
      let request = NSFetchRequest(entityName: entityName)
      request.predicate = NSPredicate(format: "%K = %@", entity.sync_localPrimaryKey(), localPrimaryKey)
      do {
        let objects = try executeFetchRequest(request)
        return objects.first as? NSManagedObject
      } catch {
        fatalError("Failed to fetch request for entityName: \(entityName), predicate: \(request.predicate)")
      }
    } else if let parentRelationshipName = parentRelationshipName {
      // More info: https://github.com/hyperoslo/Sync/pull/72
      return parent?.valueForKey(parentRelationshipName) as? NSManagedObject
    } else {
      return nil
    }
  }
}
