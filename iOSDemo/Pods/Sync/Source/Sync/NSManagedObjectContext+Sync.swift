import CoreData
import Sync.NSEntityDescription_PrimaryKey

public extension NSManagedObjectContext {
    /**
     Safely fetches a NSManagedObject in the current context. If no localPrimaryKey is provided then it will check for the parent entity and use that. Otherwise it will return nil.
     - parameter entityName: The name of the Core Data entity.
     - parameter localPrimaryKey: The primary key.
     - parameter parent: The parent of the object.
     - parameter parentRelationshipName: The name of the relationship with the parent.
     - returns: A NSManagedObject contained in the provided context.
     */
    public func safeObject(_ entityName: String, localPrimaryKey: Any?, parent: NSManagedObject?, parentRelationshipName: String?) -> NSManagedObject? {
        var result: NSManagedObject?

        if let localPrimaryKey = localPrimaryKey as? NSObject, let entity = NSEntityDescription.entity(forEntityName: entityName, in: self) {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            request.predicate = NSPredicate(format: "%K = %@", entity.sync_localPrimaryKey(), localPrimaryKey)
            do {
                let objects = try fetch(request)
                result = objects.first as? NSManagedObject
            } catch {
                fatalError("Failed to fetch request for entityName: \(entityName), predicate: \(String(describing: request.predicate))")
            }
        } else if let parentRelationshipName = parentRelationshipName {
            // More info: https://github.com/3lvis/Sync/pull/72
            result = parent?.value(forKey: parentRelationshipName) as? NSManagedObject
        }

        return result
    }

    public func managedObjectIDs(in entityName: String, usingAsKey attributeName: String, predicate: NSPredicate?) -> [AnyHashable: NSManagedObjectID] {
        var result = [AnyHashable: NSManagedObjectID]()

        self.performAndWait {
            let expression = NSExpressionDescription()
            expression.name = "objectID"
            expression.expression = NSExpression.expressionForEvaluatedObject()
            expression.expressionResultType = .objectIDAttributeType

            let request = NSFetchRequest<NSDictionary>(entityName: entityName)
            request.predicate = predicate
            request.resultType = .dictionaryResultType
            request.propertiesToFetch = [expression, attributeName]

            do {
                let objects = try self.fetch(request)
                for object in objects {
                    let fetchedID = object[attributeName] as! NSObject
                    let objectID = object["objectID"] as! NSManagedObjectID

                    if let _ = result[fetchedID] {
                        self.delete(self.object(with: objectID))
                    } else {
                        result[fetchedID] = objectID
                    }
                }
            } catch let error as NSError {
                print("error: \(error)")
            }
        }

        return result
    }
}
