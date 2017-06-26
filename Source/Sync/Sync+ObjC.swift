/**
 The enum for Objective-C, equals to Sync.OperationOptions in Swift.
 Objective-C does not support array of enum as parameter, thus we have listed all possible combinations in this enum.
 */
@objc public enum CompatibleOperationOptions: Int {
    case insert = 0
    case update = 1
    case delete = 2
    case insertUpdate = 3
    case insertDelete = 4
    case updateDelete = 5
    case all = 6

    /**
     Transfer Objective-C enum to Sync.OperationOptions in Swift
     */
    var operationOptions: Sync.OperationOptions {
        switch self {
        case .insert:
            return [.insert]
        case .update:
            return [.update]
        case .delete:
            return [.delete]
        case .insertUpdate:
            return [.insert, .update]
        case .insertDelete:
            return [.insert, .delete]
        case .updateDelete:
            return [.update, .delete]
        case .all:
            return [.all]
        }
    }
}

public extension Sync {
    
    /**
     Added support for Objective-C.
     Syncs the entity using the received array of dictionaries, maps one-to-many, many-to-many and one-to-one relationships.
     It also syncs relationships where only the id is present, for example if your model is: Company -> Employee,
     and your employee has a company_id, it will try to sync using that ID instead of requiring you to provide the
     entire company object inside the employees dictionary.
     - parameter changes: The array of dictionaries used in the sync process.
     - parameter entityName: The name of the entity to be synced.
     - parameter dataStack: The DataStack instance.
     - parameter operations: The type of operations to be applied to the data, it should be a value of CompatibleOperationOptions.
     - parameter completion: The completion block, it returns an error if something in the Sync process goes wrong.
     */
    public class func compatibleChanges(_ changes: [[String: Any]], inEntityNamed entityName: String, dataStack: DataStack, operations: CompatibleOperationOptions, completion: ((_ error: NSError?) -> Void)?) {
        self.changes(changes, inEntityNamed: entityName, dataStack: dataStack, operations: operations.operationOptions, completion: completion)
    }
    
    /**
     Added support for Objective-C.
     Syncs the entity using the received array of dictionaries, maps one-to-many, many-to-many and one-to-one relationships.
     It also syncs relationships where only the id is present, for example if your model is: Company -> Employee,
     and your employee has a company_id, it will try to sync using that ID instead of requiring you to provide the
     entire company object inside the employees dictionary.
     - parameter changes: The array of dictionaries used in the sync process.
     - parameter entityName: The name of the entity to be synced.
     - parameter predicate: The predicate used to filter out changes, if you want to exclude some local items to be taken in
     account in the Sync process, you just need to provide this predicate.
     - parameter dataStack: The DataStack instance.
     - parameter operations: The type of operations to be applied to the data, it should be a value of CompatibleOperationOptions.
     - parameter completion: The completion block, it returns an error if something in the Sync process goes wrong.
     */
    public class func compatibleChanges(_ changes: [[String: Any]], inEntityNamed entityName: String, predicate: NSPredicate?, dataStack: DataStack, operations: CompatibleOperationOptions, completion: ((_ error: NSError?) -> Void)?) {
        dataStack.performInNewBackgroundContext { backgroundContext in
            self.changes(changes, inEntityNamed: entityName, predicate: predicate, dataStack: dataStack, operations: operations.operationOptions, completion: completion)
        }
    }
}
