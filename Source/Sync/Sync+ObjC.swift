import Foundation

@objc public enum ObjcOperationOptions: Int {
    case insert = 0
    case update = 1
    case delete = 2
    case insertUpdate = 3
    case insertDelete = 4
    case updateDelete = 5
    case all = 6
}

public extension Sync {
    
    public class func objc_changes(_ changes: [[String: Any]], inEntityNamed entityName: String, dataStack: DataStack, operations: ObjcOperationOptions, completion: ((_ error: NSError?) -> Void)?) {
        self.changes(changes, inEntityNamed: entityName, dataStack: dataStack, operations: self.operationOptionsFrom(operations), completion: completion)
    }
    
    public class func objc_changes(_ changes: [[String: Any]], inEntityNamed entityName: String, predicate: NSPredicate?, dataStack: DataStack, operations: ObjcOperationOptions, completion: ((_ error: NSError?) -> Void)?) {
        dataStack.performInNewBackgroundContext { backgroundContext in
            self.changes(changes, inEntityNamed: entityName, predicate: predicate, dataStack: dataStack, operations: self.operationOptionsFrom(operations), completion: completion)
        }
    }
    
    private class func operationOptionsFrom(_ objcOperationOptions: ObjcOperationOptions) -> Sync.OperationOptions {
        switch objcOperationOptions {
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
