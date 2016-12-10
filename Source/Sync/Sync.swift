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

    public struct OperationOptions: OptionSet {
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

    var changes: [[String: Any]]
    var entityName: String
    var predicate: NSPredicate?
    var filterOperations = Sync.OperationOptions.All
    var parent: NSManagedObject?
    var parentRelationship: NSRelationshipDescription?
    var context: NSManagedObjectContext?
    unowned var dataStack: DATAStack

    public init(changes: [[String: Any]], inEntityNamed entityName: String, predicate: NSPredicate? = nil, parent: NSManagedObject? = nil, parentRelationship: NSRelationshipDescription? = nil, context: NSManagedObjectContext? = nil, dataStack: DATAStack, operations: Sync.OperationOptions = .All) {
        self.changes = changes
        self.entityName = entityName
        self.predicate = predicate
        self.parent = parent
        self.parentRelationship = parentRelationship
        self.context = context
        self.dataStack = dataStack
        self.filterOperations = operations
    }

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

    public override func start() {
        if self.isCancelled {
            self.updateExecuting(false)
            self.updateFinished(true)
        } else {
            self.updateExecuting(true)
            if let context = self.context {
                context.perform {
                    self.perform(using: context)
                }
            } else {
                self.dataStack.performInNewBackgroundContext { backgroundContext in
                    self.perform(using: backgroundContext)
                }
            }
        }
    }

    func perform(using context: NSManagedObjectContext) {
        do {
            try Sync.changes(self.changes, inEntityNamed: self.entityName, predicate: self.predicate, parent: self.parent, parentRelationship: self.parentRelationship, inContext: context, operations: self.filterOperations, shouldContinueBlock: { () -> Bool in
                return !self.isCancelled
            }, objectJSONBlock: { objectJSON -> [String: Any] in
                return self.delegate?.sync(self, willInsert: objectJSON, in: self.entityName, parent: self.parent) ?? objectJSON
            })
        } catch let error as NSError {
            print("Failed syncing changes \(error)")

            self.updateExecuting(false)
            self.updateFinished(true)
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

    public class func changes(_ changes: [[String: Any]], inEntityNamed entityName: String, predicate: NSPredicate?, parent: NSManagedObject?, parentRelationship: NSRelationshipDescription?, inContext context: NSManagedObjectContext, operations: Sync.OperationOptions, completion: ((_ error: NSError?) -> Void)?) {

        var error: NSError?
        do {
            try self.changes(changes, inEntityNamed: entityName, predicate: predicate, parent: parent, parentRelationship: parentRelationship, inContext: context, operations: operations, shouldContinueBlock: nil, objectJSONBlock: nil)
        } catch let syncError as NSError {
            error = syncError
        }

        if TestCheck.isTesting {
            completion?(error)
        } else {
            DispatchQueue.main.async {
                completion?(error)
            }
        }
    }

    class func changes(_ changes: [[String: Any]], inEntityNamed entityName: String, predicate: NSPredicate?, parent: NSManagedObject?, parentRelationship: NSRelationshipDescription?, inContext context: NSManagedObjectContext, operations: Sync.OperationOptions, shouldContinueBlock: (() -> Bool)?, objectJSONBlock: ((_ objectJSON: [String: Any]) -> [String: Any])?) throws {
        guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else { fatalError("Entity named \(entityName) not found.") }

        let localPrimaryKey = entity.sync_localPrimaryKey()
        let remotePrimaryKey = entity.sync_remotePrimaryKey()
        let shouldLookForParent = parent == nil && predicate == nil

        var finalPredicate = predicate
        if let parentEntity = entity.sync_parentEntity(), shouldLookForParent {
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
            let shouldContinue = shouldContinueBlock?() ?? true
            guard shouldContinue else { return }

            let created = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
            let interceptedJSON = objectJSONBlock?(JSON) ?? JSON
            created.sync_fill(with: interceptedJSON, parent: parent, parentRelationship: parentRelationship, context: context, operations: operations, shouldContinueBlock: shouldContinueBlock, objectJSONBlock: objectJSONBlock)
        }) { JSON, updatedObject in
            let shouldContinue = shouldContinueBlock?() ?? true
            guard shouldContinue else { return }

            updatedObject.sync_fill(with: JSON, parent: parent, parentRelationship: parentRelationship, context: context, operations: operations, shouldContinueBlock: shouldContinueBlock, objectJSONBlock: objectJSONBlock)
        }

        if context.hasChanges {
            let shouldContinue = shouldContinueBlock?() ?? true
            if shouldContinue {
                try context.save()
            } else {
                context.reset()
            }
        }
    }

    /// Fetches a managed object for the provided primary key in an specific entity.
    ///
    /// - Parameters:
    ///   - id: The primary key.
    ///   - entityName: The name of the entity.
    ///   - context: The context to be used, make sure that this method gets called in the same thread as the context using `perform` or `performAndWait`.
    /// - Returns: A managed object for a provided primary key in an specific entity.
    /// - Throws: Core Data related issues.
    @discardableResult
    public class func fetch<ResultType: NSManagedObject>(_ id: Any, inEntityNamed entityName: String, using context: NSManagedObjectContext) throws -> ResultType? {
        Sync.verifyContextSafety(context: context)

        guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else { abort() }
        let localPrimaryKey = entity.sync_localPrimaryKey()
        let fetchRequest = NSFetchRequest<ResultType>(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "%K = %@", localPrimaryKey, id as! NSObject)

        let objects = try context.fetch(fetchRequest)

        return objects.first
    }

    /// Inserts or updates an object using the given changes dictionary in an specific entity.
    ///
    /// - Parameters:
    ///   - changes: The dictionary to be used to update or create the object.
    ///   - entityName: The name of the entity.
    ///   - context: The context to be used, make sure that this method gets called in the same thread as the context using `perform` or `performAndWait`.
    /// - Returns: The inserted or updated object. If you call this method from a background context, make sure to not use this on the main thread.
    /// - Throws: Core Data related issues.
    @discardableResult
    public class func insertOrUpdate<ResultType: NSManagedObject>(_ changes: [String: Any], inEntityNamed entityName: String, using context: NSManagedObjectContext) throws -> ResultType {
        Sync.verifyContextSafety(context: context)

        guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else { abort() }
        let localPrimaryKey = entity.sync_localPrimaryKey()
        let remotePrimaryKey = entity.sync_remotePrimaryKey()
        guard let id = changes[remotePrimaryKey] as? NSObject else { fatalError("Couldn't find primary key \(remotePrimaryKey) in JSON for object in entity \(entityName)") }
        let fetchRequest = NSFetchRequest<ResultType>(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "%K = %@", localPrimaryKey, id)

        let fetchedObjects = try context.fetch(fetchRequest)
        let insertedOrUpdatedObjects: [ResultType]
        if fetchedObjects.count > 0 {
            insertedOrUpdatedObjects = fetchedObjects
        } else {
            let inserted = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context) as! ResultType
            insertedOrUpdatedObjects = [inserted]
        }

        for object in insertedOrUpdatedObjects {
            object.sync_fill(with: changes, parent: nil, parentRelationship: nil, context: context, operations: [.All], shouldContinueBlock: nil, objectJSONBlock: nil)
        }

        if context.hasChanges {
            try context.save()
        }

        return insertedOrUpdatedObjects.first!
    }

    /// Updates an object using the given changes dictionary for the provided primary key in an specific entity.
    ///
    /// - Parameters:
    ///   - id: The primary key.
    ///   - changes: The dictionary to be used to update the object.
    ///   - entityName: The name of the entity.
    ///   - context: The context to be used, make sure that this method gets called in the same thread as the context using `perform` or `performAndWait`.
    /// - Returns: The updated object, if not found it returns nil. If you call this method from a background context, make sure to not use this on the main thread.
    /// - Throws: Core Data related issues.
    @discardableResult
    public class func update<ResultType: NSManagedObject>(_ id: Any, with changes: [String: Any], inEntityNamed entityName: String, using context: NSManagedObjectContext) throws -> ResultType? {
        Sync.verifyContextSafety(context: context)

        guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else { fatalError("Couldn't find an entity named \(entityName)") }
        let localPrimaryKey = entity.sync_localPrimaryKey()
        let fetchRequest = NSFetchRequest<ResultType>(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "%K = %@", localPrimaryKey, id as! NSObject)

        let objects = try context.fetch(fetchRequest)
        for updated in objects {
            updated.sync_fill(with: changes, parent: nil, parentRelationship: nil, context: context, operations: [.All], shouldContinueBlock: nil, objectJSONBlock: nil)
        }

        if context.hasChanges {
            try context.save()
        }

        return objects.first
    }

    /// Deletes a managed object for the provided primary key in an specific entity.
    ///
    /// - Parameters:
    ///   - id: The primary key.
    ///   - entityName: The name of the entity.
    ///   - context: The context to be used, make sure that this method gets called in the same thread as the context using `perform` or `performAndWait`.
    /// - Throws: Core Data related issues.
    public class func delete(_ id: Any, inEntityNamed entityName: String, using context: NSManagedObjectContext) throws {
        Sync.verifyContextSafety(context: context)

        guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else { abort() }
        let localPrimaryKey = entity.sync_localPrimaryKey()
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "%K = %@", localPrimaryKey, id as! NSObject)

        let objects = try context.fetch(fetchRequest)
        guard objects.count > 0 else { return }

        for deletedObject in objects {
            context.delete(deletedObject)
        }

        if context.hasChanges {
            try context.save()
        }
    }

    fileprivate class func verifyContextSafety(context: NSManagedObjectContext) {
        if Thread.isMainThread && context.concurrencyType == .privateQueueConcurrencyType {
            fatalError("Background context used in the main thread. Use context's `perform` method")
        }

        if !Thread.isMainThread && context.concurrencyType == .mainQueueConcurrencyType {
            fatalError("Main context used in a background thread. Use context's `perform` method.")
        }
    }
}
