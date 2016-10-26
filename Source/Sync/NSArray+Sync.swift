import Foundation
import DATAStack
import SYNCPropertyMapper

extension NSArray {
    /**
     Filters the items using the provided predicate, useful to exclude JSON objects from a JSON array by using a predicate.
     - parameter entityName: The name of the entity to be synced.
     - parameter predicate: The predicate used to filter out changes, if you want to exclude some items, you just need to provide this predicate.
     - parameter parent: The parent of the entity, optional since many entities are orphans.
     - parameter dataStack: The DATAStack instance.
     */
    /*
    func preprocessForEntityNamed(_ entityName: String, predicate: NSPredicate, parent: NSManagedObject?, dataStack: DATAStack, operations: Sync.OperationOptions) -> [[String : Any]] {
        var filteredChanges = [[String : Any]]()
        let validClasses = [NSDate.classForCoder(), NSNumber.classForCoder(), NSString.classForCoder()]
        if let predicate = predicate as? NSComparisonPredicate, let selfArray = self as? [[String : Any]] , validClasses.contains(where: { $0 == predicate.rightExpression.classForCoder }) {
            var objectChanges = [NSManagedObject]()
            let context = dataStack.newDisposableMainContext()
            if let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) {
                for objectDictionary in selfArray {
                    let object = NSManagedObject(entity: entity, insertInto: context)
                    object.sync_fillWithDictionary(objectDictionary, parent: parent, parentRelationship: nil, dataStack: dataStack, operations: operations)
                    objectChanges.append(object)
                }

                guard let filteredArray = (objectChanges as NSArray).filtered(using: predicate) as? [NSManagedObject] else { fatalError("Couldn't cast filteredArray as [NSManagedObject]: \(objectChanges), predicate: \(predicate)") }
                for filteredObject in filteredArray  {
                    let change = filteredObject.hyp_dictionary(using: .array)
                    filteredChanges.append(change)
                }
            }
        }
        
        return filteredChanges
    }
     */
}
