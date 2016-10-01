import CoreData

public class DATAObjectIDs: NSObject {
    public class func objectIDs(inEntityNamed entityName: String, withAttributesNamed attributeName: String, context: NSManagedObjectContext) -> [AnyHashable: Any] {
        return self.generateObjectIDs(inEntityNamed: entityName, withAttributesNamed: attributeName, context: context, predicate: nil, sortDescriptors: nil)
    }

    public class func objectIDs(inEntityNamed entityName: String, withAttributesNamed attributeName: String, context: NSManagedObjectContext, predicate: NSPredicate?) -> [AnyHashable: Any] {
        return self.generateObjectIDs(inEntityNamed: entityName, withAttributesNamed: attributeName, context: context, predicate: predicate, sortDescriptors: nil)
    }

    public class func objectIDs(inEntityNamed entityName: String, withAttributesNamed attributeName: String, context: NSManagedObjectContext, sortDescriptors: [NSSortDescriptor]) -> [AnyHashable: Any] {
        return self.generateObjectIDs(inEntityNamed: entityName, withAttributesNamed: attributeName, context: context, predicate: nil, sortDescriptors: nil)
    }

    public class func objectIDs(inEntityNamed entityName: String, withAttributesNamed attributeName: String, context: NSManagedObjectContext, predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]) -> [AnyHashable: Any] {
        return self.generateObjectIDs(inEntityNamed: entityName, withAttributesNamed: attributeName, context: context, predicate: predicate, sortDescriptors: sortDescriptors)
    }

    public class func objectIDs(inEntityNamed entityName: String, context: NSManagedObjectContext) -> [Any] {
        return self.generateObjectIDs(inEntityNamed: entityName, context: context, predicate: nil, sortDescriptors: nil)
    }

    public class func objectIDs(inEntityNamed entityName: String, context: NSManagedObjectContext, predicate: NSPredicate) -> [Any] {
        return self.generateObjectIDs(inEntityNamed: entityName, context: context, predicate: predicate, sortDescriptors: nil)
    }

    public class func objectIDs(inEntityNamed entityName: String, context: NSManagedObjectContext, sortDescriptors: [NSSortDescriptor]) -> [Any] {
        return self.generateObjectIDs(inEntityNamed: entityName, context: context, predicate: nil, sortDescriptors: sortDescriptors)
    }

    public class func objectIDs(inEntityNamed entityName: String, context: NSManagedObjectContext, predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]) -> [Any] {
        return self.generateObjectIDs(inEntityNamed: entityName, context: context, predicate: predicate, sortDescriptors: sortDescriptors)
    }

    public class func attributes(inEntityNamed entityName: String, attributeName: String, context: NSManagedObjectContext) -> [Any] {
        return self.generateAttributes(inEntityNamed: entityName, attributeName: attributeName, context: context, predicate: nil, sortDescriptors: nil)
    }

    public class func attributes(inEntityNamed entityName: String, attributeName: String, context: NSManagedObjectContext, predicate: NSPredicate) -> [Any] {
        return self.generateAttributes(inEntityNamed: entityName, attributeName: attributeName, context: context, predicate: predicate, sortDescriptors: nil)
    }

    public class func attributes(inEntityNamed entityName: String, attributeName: String, context: NSManagedObjectContext, sortDescriptors: [NSSortDescriptor]) -> [Any] {
        return self.generateAttributes(inEntityNamed: entityName, attributeName: attributeName, context: context, predicate: nil, sortDescriptors: sortDescriptors)
    }

    public class func attributes(inEntityNamed entityName: String, attributeName: String, context: NSManagedObjectContext, predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]) -> [Any] {
        return self.generateAttributes(inEntityNamed: entityName, attributeName: attributeName, context: context, predicate: predicate, sortDescriptors: sortDescriptors)
    }

    class func generateObjectIDs(inEntityNamed entityName: String, withAttributesNamed attributeName: String, context: NSManagedObjectContext, predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) -> [AnyHashable: Any] {
        var result = [AnyHashable: Any]()

        context.performAndWait {
            let expression = NSExpressionDescription()
            expression.name = "objectID"
            expression.expression = NSExpression.expressionForEvaluatedObject()
            expression.expressionResultType = .objectIDAttributeType

            let request = NSFetchRequest<NSDictionary>(entityName: entityName)
            request.predicate = predicate
            request.resultType = .dictionaryResultType
            request.propertiesToFetch = [expression, attributeName]
            request.sortDescriptors = sortDescriptors

            do {
                let objects = try context.fetch(request)
                for object in objects {
                    let fetchedID = object[attributeName] as! NSObject
                    let objectID = object["objectID"] as! NSManagedObjectID

                    if let _ = result[fetchedID] {
                        context.delete(context.object(with: objectID))
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

        context.performAndWait {
            let request = NSFetchRequest<NSManagedObjectID>(entityName: entityName)
            request.predicate = predicate;
            request.resultType = .managedObjectIDResultType

            do {
                objectIDs = try context.fetch(request)
            } catch let error as NSError {
                print("error: \(error)")
            }
        }

        return objectIDs
    }

    class func generateAttributes(inEntityNamed entityName: String, attributeName: String, context: NSManagedObjectContext, predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) -> [Any] {
        var attributes = [Any]()

        context.performAndWait {
            let expression = NSExpressionDescription()
            expression.name = "objectID"
            expression.expression = NSExpression.expressionForEvaluatedObject()
            expression.expressionResultType = .objectIDAttributeType

            let request = NSFetchRequest<NSDictionary>(entityName: entityName)
            request.predicate = predicate
            request.resultType = .dictionaryResultType
            request.propertiesToFetch = [expression, attributeName]
            request.sortDescriptors = sortDescriptors

            do {
                let objects = try context.fetch(request)
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
