import CoreData

public class DATAObjectIDs: NSObject {
    public class func objectIDs(inEntityNamed entityName: String, withAttributesNamed attributeName: String, context: NSManagedObjectContext, predicate: NSPredicate?) -> [NSObject: AnyObject] {
        return self.generateObjectIDs(inEntityNamed: entityName, withAttributesNamed: attributeName, context: context, predicate: predicate, sortDescriptors: nil)
    }

    class func generateObjectIDs(inEntityNamed entityName: String, withAttributesNamed attributeName: String, context: NSManagedObjectContext, predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) -> [NSObject: AnyObject] {
        var result = [NSObject: AnyObject]()

        context.performBlockAndWait { 
            let expression = NSExpressionDescription()
            expression.name = "objectID"
            expression.expression = NSExpression.expressionForEvaluatedObject()
            expression.expressionResultType = .ObjectIDAttributeType

            let request = NSFetchRequest(entityName: entityName)
            request.predicate = predicate
            request.resultType = .DictionaryResultType
            request.propertiesToFetch = [expression, attributeName]
            request.sortDescriptors = sortDescriptors

            do {
                let objects = try context.executeFetchRequest(request)
                for object in objects {
                    let fetchedID = object[attributeName] as! NSObject
                    let objectID = object["objectID"] as! NSManagedObjectID

                    if let _ = result[fetchedID] {
                        context.deleteObject(context.objectWithID(objectID))
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

    class func generateObjectIDs(inEntityNamed entityName: String, context: NSManagedObjectContext, predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) -> [Any] {
        var objectIDs = [NSManagedObjectID]()

        context.performBlockAndWait {
            let request = NSFetchRequest(entityName: entityName)
            request.predicate = predicate;
            request.resultType = .ManagedObjectIDResultType

            do {
                objectIDs = try context.executeFetchRequest(request) as? [NSManagedObjectID] ?? [NSManagedObjectID]()
            } catch let error as NSError {
                print("error: \(error)")
            }
        }

        return objectIDs
    }

    class func generateAttributes(inEntityNamed entityName: String, attributeName: String, context: NSManagedObjectContext, predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) -> [Any] {
        var attributes = [Any]()

        context.performBlockAndWait {
            let expression = NSExpressionDescription()
            expression.name = "objectID"
            expression.expression = NSExpression.expressionForEvaluatedObject()
            expression.expressionResultType = .ObjectIDAttributeType

            let request = NSFetchRequest(entityName: entityName)
            request.predicate = predicate
            request.resultType = .DictionaryResultType
            request.propertiesToFetch = [expression, attributeName]
            request.sortDescriptors = sortDescriptors

            do {
                let objects = try context.executeFetchRequest(request)
                for object in objects {
                    if let fetchedID = object[attributeName] {
                        attributes.append(fetchedID)
                    }
                }
            } catch let error as NSError {
                print("error: \(error)")
            }
        }

        return attributes
    }
}
