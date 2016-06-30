import Foundation
import DATAStack
import NSManagedObject_HYPPropertyMapper
import DATAFilter

public extension NSArray {
  /**
   Filters the items using the provided predicate, useful to exclude JSON objects from a JSON array by using a predicate.
   - parameter entityName: The name of the entity to be synced.
   - parameter predicate: The predicate used to filter out changes, if you want to exclude some items, you just need to provide this predicate.
   - parameter parent: The parent of the entity, optional since many entities are orphans.
   - parameter dataStack: The DATAStack instance.
   */
  func preprocessForEntityNamed(_ entityName: String, predicate: Predicate, parent: NSManagedObject?, dataStack: DATAStack, operations: DATAFilterOperation) -> [[String : AnyObject]] {
    var filteredChanges = [[String : AnyObject]]()
    let validClasses = [NSDate.self, NSNumber.self, NSString.self]
    if let predicate = predicate as? ComparisonPredicate, selfArray = self as? [[String : AnyObject]] where validClasses.contains({ $0 as! NSObject == predicate.rightExpression.self }) {
      var objectChanges = [NSManagedObject]()
      let context = dataStack.newDisposableMainContext()
      if let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) {
        selfArray.forEach {
          let object = NSManagedObject(entity: entity, insertInto: context)
          object.sync_fillWithDictionary($0, parent: parent, dataStack: dataStack, operations: operations)
          objectChanges.append(object)
        }

        guard let filteredArray = (objectChanges as NSArray).filtered(using: predicate) as? [NSManagedObject] else { fatalError("Couldn't cast filteredArray as [NSManagedObject]: \(objectChanges), predicate: \(predicate)") }
        for filteredObject in filteredArray  {
          if let change = filteredObject.hyp_dictionary(using: .array) as? [String : AnyObject] {
            filteredChanges.append(change)
          }
        }
      }
    }

    return filteredChanges
  }
}
