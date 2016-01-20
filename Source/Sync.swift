import CoreData
import NSEntityDescription_SYNCPrimaryKey
import DATAFilter
import NSManagedObject_HYPPropertyMapper
import DATAStack

@objc public class Sync: NSObject {
    public class func changes(changes: NSArray, inEntityNamed entityName: String, dataStack: DATAStack, completion: ((error: NSError?) -> Void)?) {

    }

    public class func changes(changes: NSArray, inEntityNamed entityName: String, predicate: NSPredicate, dataStack: DATAStack, completion: ((error: NSError?) -> Void)?) {

    }

    public class func changes(changes: NSArray, inEntityNamed entityName: String, parent: NSManagedObject, dataStack: DATAStack, completion: ((error: NSError?) -> Void)?) {

    }

    public class func changes(changes: NSArray, inEntityNamed entityName: String, predicate: NSPredicate, parent: NSManagedObject, inContext context:NSManagedObjectContext, dataStack: DATAStack, completion: ((error: NSError?) -> Void)?) {

    }
}
