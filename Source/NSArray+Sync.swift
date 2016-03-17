import Foundation
import DATAStack
import NSManagedObject_HYPPropertyMapper

public extension NSArray {
  /**
   Filters the items using the provided predicate, useful to exclude JSON objects from a JSON array by using a predicate.
   - parameter entityName: The name of the entity to be synced.
   - parameter predicate: The predicate used to filter out changes, if you want to exclude some items, you just need to provide this predicate.
   - parameter parent: The parent of the entity, optional since many entities are orphans.
   - parameter dataStack: The DATAStack instance.
   */
  func preprocessForEntityNamed(entityName: String, predicate: NSPredicate, parent: NSManagedObject?, dataStack: DATAStack) -> [[String : AnyObject]] {
    var filteredChanges = [[String : AnyObject]]()
    let validClasses = [NSDate.classForCoder(), NSNumber.classForCoder(), NSString.classForCoder()]
    if let predicate = predicate as? NSComparisonPredicate, selfArray = self as? [[String : AnyObject]] where validClasses.contains({ $0 == predicate.rightExpression.classForCoder }) {
        var objectChanges = [NSManagedObject]()
        let context = dataStack.newDisposableMainContext()
        if let entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: context) {
          selfArray.forEach {
            let object = NSManagedObject(entity: entity, insertIntoManagedObjectContext: context)
            object.sync_fillWithDictionary($0, parent: parent, dataStack: dataStack)
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

    return filteredChanges
  }
}
