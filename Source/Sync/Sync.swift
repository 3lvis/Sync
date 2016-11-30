import CoreData
import SYNCPropertyMapper
import DATAStack

public protocol SyncDelegate: class {
    /// Called before the JSON is used to create a new NSManagedObject.
    ///
    /// - parameter sync:        The Sync operation.
    /// - parameter json:        The JSON used for filling the contents of the NSManagedObject.
    /// - parameter entityNamed: The name of the entity to be created.
    /// - parameter parent:      The new item's parent. Do not mutate the contents of this element.
    ///
    /// - returns: The JSON used to create the new NSManagedObject.
    func sync(_ sync: Sync, willInsert json: [String: Any], in entityNamed: String, parent: NSManagedObject?) -> [String: Any]
}

@objc public class Sync: Operation {
    public weak var delegate: SyncDelegate?

    public struct OperationOptions : OptionSet {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let Insert = OperationOptions(rawValue: 1 << 0)
        public static let Update = OperationOptions(rawValue: 1 << 1)
        public static let Delete = OperationOptions(rawValue: 1 << 2)
        public static let All: OperationOptions = [.Insert, .Update, .Delete]
    }

    var downloadFinished = false
    var downloadExecuting = false
    var downloadCancelled = false

    public override var isFinished: Bool {
        return self.downloadFinished
    }

    public override var isExecuting: Bool {
        return self.downloadExecuting
    }

    public override var isCancelled: Bool {
        return self.downloadCancelled
    }

    public override var isAsynchronous: Bool {
        return !TestCheck.isTesting
    }

    var changes: [[String : Any]]
    var entityName: String
    var predicate: NSPredicate?
    var filterOperations = Sync.OperationOptions.All
    var parent: NSManagedObject?
    var context: NSManagedObjectContext?
    unowned var dataStack: DATAStack

    public init(changes: [[String : Any]], inEntityNamed entityName: String, predicate: NSPredicate?, parent: NSManagedObject?, context: NSManagedObjectContext?, dataStack: DATAStack, operations: Sync.OperationOptions = .All) {
        self.changes = changes
        self.entityName = entityName
        self.predicate = predicate
        self.parent = parent
        self.context = context
        self.dataStack = dataStack
        self.filterOperations = operations
    }

    public init(changes: [[String : Any]], inEntityNamed entityName: String, dataStack: DATAStack, operations: Sync.OperationOptions = .All) {
        self.changes = changes
        self.entityName = entityName
        self.dataStack = dataStack
        self.filterOperations = operations
    }

    public init(changes: [[String : Any]], inEntityNamed entityName: String, predicate: NSPredicate?, dataStack: DATAStack, operations: Sync.OperationOptions = .All) {
        self.changes = changes
        self.entityName = entityName
        self.predicate = predicate
        self.dataStack = dataStack
        self.filterOperations = operations
    }

    public override func start() {
        func updateExecuting(_ isExecuting: Bool) {
            self.willChangeValue(forKey: "isExecuting")
            self.downloadExecuting = isExecuting
            self.didChangeValue(forKey: "isExecuting")
        }

        func updateFinished(_ isFinished: Bool) {
            self.willChangeValue(forKey: "isFinished")
            self.downloadFinished = isFinished
            self.didChangeValue(forKey: "isFinished")
        }

        if self.isCancelled {
            updateExecuting(false)
            updateFinished(true)
        } else {
            updateExecuting(true)
            if let context = self.context {
                context.perform {
                    self.changes(self.changes, inEntityNamed: self.entityName, predicate: self.predicate, parent: self.parent, parentRelationship: nil, inContext: context, dataStack: self.dataStack, operations: self.filterOperations) { error in
                        updateExecuting(false)
                        updateFinished(true)
                    }
                }
            } else {
                dataStack.performInNewBackgroundContext { backgroundContext in
                    self.changes(self.changes, inEntityNamed: self.entityName, predicate: self.predicate, parent: self.parent, parentRelationship: nil, inContext: backgroundContext, dataStack: self.dataStack, operations: self.filterOperations) { error in
                        updateExecuting(false)
                        updateFinished(true)
                    }
                }
            }
        }
    }

    public override func cancel() {
        func updateCancelled(_ isCancelled: Bool) {
            self.willChangeValue(forKey: "isCancelled")
            self.downloadCancelled = isCancelled
            self.didChangeValue(forKey: "isCancelled")
        }

        updateCancelled(true)
    }

    public class func changes(_ changes: [[String : Any]], inEntityNamed entityName: String, predicate: NSPredicate?, parent: NSManagedObject?, parentRelationship: NSRelationshipDescription?, inContext context: NSManagedObjectContext, operations: Sync.OperationOptions, completion: ((_ error: NSError?) -> Void)?) {
        guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else { abort() }

        let localPrimaryKey = entity.sync_localPrimaryKey()
        let remotePrimaryKey = entity.sync_remotePrimaryKey()
        let shouldLookForParent = parent == nil && predicate == nil

        var finalPredicate = predicate
        if let parentEntity = entity.sync_parentEntity() , shouldLookForParent {
            finalPredicate = NSPredicate(format: "%K = nil", parentEntity.name)
        }

        if localPrimaryKey.isEmpty {
            fatalError("Local primary key not found for entity: \(entityName), add a primary key named id or mark an existing attribute using hyper.isPrimaryKey")
        }

        if remotePrimaryKey.isEmpty {
            fatalError("Remote primary key not found for entity: \(entityName), we were looking for id, if your remote ID has a different name consider using hyper.remoteKey to map to the right value")
        }

        let dataFilterOperations = DATAFilter.Operation(rawValue: operations.rawValue)
        DATAFilter.changes(changes, inEntityNamed: entityName, predicate: finalPredicate, operations: dataFilterOperations, localPrimaryKey: localPrimaryKey, remotePrimaryKey: remotePrimaryKey, context: context, inserted: { JSON in
            let created = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
            created.sync_fill(with: JSON, parent: parent, parentRelationship: parentRelationship, context: context, operations: operations)
        }) { JSON, updatedObject in
            updatedObject.sync_fill(with: JSON, parent: parent, parentRelationship: parentRelationship, context: context, operations: operations)
        }

        var syncError: NSError?
        if context.hasChanges {
            do {
                try context.save()
            } catch let error as NSError {
                syncError = error
            } catch {
                fatalError("Fatal error")
            }
        }

        if TestCheck.isTesting {
            completion?(syncError)
        } else {
            DispatchQueue.main.async {
                completion?(syncError)
            }
        }
    }

    func changes(_ changes: [[String : Any]], inEntityNamed entityName: String, predicate: NSPredicate?, parent: NSManagedObject?, parentRelationship: NSRelationshipDescription?, inContext context: NSManagedObjectContext, dataStack: DATAStack, operations: Sync.OperationOptions, completion: ((_ error: NSError?) -> Void)?) {
        guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else { abort() }

        let localPrimaryKey = entity.sync_localPrimaryKey()
        let remotePrimaryKey = entity.sync_remotePrimaryKey()
        let shouldLookForParent = parent == nil && predicate == nil

        var finalPredicate = predicate
        if let parentEntity = entity.sync_parentEntity() , shouldLookForParent {
            finalPredicate = NSPredicate(format: "%K = nil", parentEntity.name)
        }

        if localPrimaryKey.isEmpty {
            fatalError("Local primary key not found for entity: \(entityName), add a primary key named id or mark an existing attribute using hyper.isPrimaryKey")
        }

        if remotePrimaryKey.isEmpty {
            fatalError("Remote primary key not found for entity: \(entityName), we were looking for id, if your remote ID has a different name consider using hyper.remoteKey to map to the right value")
        }

        let dataFilterOperations = DATAFilter.Operation(rawValue: operations.rawValue)
        DATAFilter.changes(changes as [[String : Any]], inEntityNamed: entityName, predicate: finalPredicate, operations: dataFilterOperations, localPrimaryKey: localPrimaryKey, remotePrimaryKey: remotePrimaryKey, context: context, inserted: { JSON in
            guard self.isCancelled == false else { return }

            let created = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
            let interceptedJSON = self.delegate?.sync(self, willInsert: JSON, in: entityName, parent: parent) ?? JSON
            created.sync_fill(with: interceptedJSON, parent: parent, parentRelationship: parentRelationship, context: context, operations: operations)
        }) { JSON, updatedObject in
            guard self.isCancelled == false else { return }
            updatedObject.sync_fill(with: JSON, parent: parent, parentRelationship: parentRelationship, context: context, operations: operations)
        }

        var syncError: NSError?
        if context.hasChanges {
            if self.isCancelled {
                context.reset()
            } else {
                do {
                    try context.save()
                } catch let error as NSError {
                    syncError = error
                } catch {
                    fatalError("Fatal error")
                }
            }
        }
        
        completion?(syncError)
    }
}
