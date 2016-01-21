import Foundation
import DATAStack
import NSManagedObject_HYPPropertyMapper

public extension NSArray {
    func preprocessForEntityNamed(entityName: String, predicate: NSPredicate, parent: NSManagedObject, dataStack: DATAStack) -> [[String : AnyObject]] {
        var filteredChanges = [[String : AnyObject]]()
        if predicate.isKindOfClass(NSComparisonPredicate.self), let castedPredicate = predicate as? NSComparisonPredicate, selfArray = self as? [[String : AnyObject]] {
            let rightExpression = castedPredicate.rightExpression
            let rightValue = rightExpression.constantValue
            let rightValueCanBeCompared = rightValue.isKindOfClass(NSDate.self) || rightValue.isKindOfClass(NSNumber.self) || rightValue.isKindOfClass(NSString.self)
            if (rightValueCanBeCompared) {
                var objectChanges = [NSManagedObject]()
                let context = dataStack.newDisposableMainContext()
                if let entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: context) {
                    for change in selfArray {
                        let object = NSManagedObject(entity: entity, insertIntoManagedObjectContext: context)
                        object.hyp_fillWithDictionary(change)
                        object.sync_processRelationshipsUsingDictionary(change, parent: parent, dataStack: dataStack)
                        objectChanges.append(object)
                    }

                    let filteredArray = (objectChanges as NSArray).filteredArrayUsingPredicate(predicate)
                    for filteredObject in filteredArray as! [NSManagedObject] {
                        if let change = filteredObject.hyp_dictionaryUsingRelationshipType(.Array) as? [String : AnyObject] {
                            filteredChanges.append(change)
                        }
                    }
                }
            }
        }

        return filteredChanges
    }
}