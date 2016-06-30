import CoreData
import NSEntityDescription_SYNCPrimaryKey
import DATAFilter
import NSManagedObject_HYPPropertyMapper
import DATAStack

@objc public class Sync: Operation {
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
    return true
  }

  var changes: [[String : AnyObject]]
  var entityName: String
  weak var predicate: Predicate?
  unowned var dataStack: DATAStack
  var filterOperations = DATAFilterOperation.all

  public init(changes: [[String : AnyObject]], inEntityNamed entityName: String, predicate: Predicate?, dataStack: DATAStack, operations: DATAFilterOperation = .all) {
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
      dataStack.performInNewBackgroundContext { backgroundContext in
        self.changes(self.changes, inEntityNamed: self.entityName, predicate: self.predicate, parent: nil, inContext: backgroundContext, dataStack: self.dataStack, operations: self.filterOperations)
        updateExecuting(false)
        updateFinished(true)
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

  /**
   Syncs the entity using the received array of dictionaries, maps one-to-many, many-to-many and one-to-one relationships.
   It also syncs relationships where only the id is present, for example if your model is: Company -> Employee,
   and your employee has a company_id, it will try to sync using that ID instead of requiring you to provide the
   entire company object inside the employees dictionary.
   - parameter changes: The array of dictionaries used in the sync process.
   - parameter entityName: The name of the entity to be synced.
   - parameter dataStack: The DATAStack instance.
   - parameter completion: The completion block, it returns an error if something in the Sync process goes wrong.
   */
  public class func changes(_ changes: [[String : AnyObject]], inEntityNamed entityName: String, dataStack: DATAStack, completion: ((error: NSError?) -> Void)?) {
    self.changes(changes, inEntityNamed: entityName, predicate: nil, dataStack: dataStack, operations: .all, completion: completion)
  }

  /**
   Syncs the entity using the received array of dictionaries, maps one-to-many, many-to-many and one-to-one relationships.
   It also syncs relationships where only the id is present, for example if your model is: Company -> Employee,
   and your employee has a company_id, it will try to sync using that ID instead of requiring you to provide the
   entire company object inside the employees dictionary.
   - parameter changes: The array of dictionaries used in the sync process.
   - parameter entityName: The name of the entity to be synced.
   - parameter dataStack: The DATAStack instance.
   - parameter operations: The type of operations to be applied to the data, Insert, Update, Delete or any possible combination.
   - parameter completion: The completion block, it returns an error if something in the Sync process goes wrong.
   */
  public class func changes(_ changes: [[String : AnyObject]], inEntityNamed entityName: String, dataStack: DATAStack, operations: DATAFilterOperation, completion: ((error: NSError?) -> Void)?) {
    self.changes(changes, inEntityNamed: entityName, predicate: nil, dataStack: dataStack, operations: operations, completion: completion)
  }

  /**
   Syncs the entity using the received array of dictionaries, maps one-to-many, many-to-many and one-to-one relationships.
   It also syncs relationships where only the id is present, for example if your model is: Company -> Employee,
   and your employee has a company_id, it will try to sync using that ID instead of requiring you to provide the
   entire company object inside the employees dictionary.
   - parameter changes: The array of dictionaries used in the sync process.
   - parameter entityName: The name of the entity to be synced.
   - parameter predicate: The predicate used to filter out changes, if you want to exclude some local items to be taken in
   account in the Sync process, you just need to provide this predicate.
   - parameter dataStack: The DATAStack instance.
   - parameter completion: The completion block, it returns an error if something in the Sync process goes wrong.
   */
  public class func changes(_ changes: [[String : AnyObject]], inEntityNamed entityName: String, predicate: Predicate?, dataStack: DATAStack, completion: ((error: NSError?) -> Void)?) {
    dataStack.performInNewBackgroundContext { backgroundContext in
      self.changes(changes, inEntityNamed: entityName, predicate: predicate, parent: nil, inContext: backgroundContext, dataStack: dataStack, operations: .all, completion: completion)
    }
  }

  /**
   Syncs the entity using the received array of dictionaries, maps one-to-many, many-to-many and one-to-one relationships.
   It also syncs relationships where only the id is present, for example if your model is: Company -> Employee,
   and your employee has a company_id, it will try to sync using that ID instead of requiring you to provide the
   entire company object inside the employees dictionary.
   - parameter changes: The array of dictionaries used in the sync process.
   - parameter entityName: The name of the entity to be synced.
   - parameter predicate: The predicate used to filter out changes, if you want to exclude some local items to be taken in
   account in the Sync process, you just need to provide this predicate.
   - parameter dataStack: The DATAStack instance.
   - parameter operations: The type of operations to be applied to the data, Insert, Update, Delete or any possible combination.
   - parameter completion: The completion block, it returns an error if something in the Sync process goes wrong.
   */
  public class func changes(_ changes: [[String : AnyObject]], inEntityNamed entityName: String, predicate: Predicate?, dataStack: DATAStack, operations: DATAFilterOperation, completion: ((error: NSError?) -> Void)?) {
    dataStack.performInNewBackgroundContext { backgroundContext in
      self.changes(changes, inEntityNamed: entityName, predicate: predicate, parent: nil, inContext: backgroundContext, dataStack: dataStack, operations: operations, completion: completion)
    }
  }

  /**
   Syncs the entity using the received array of dictionaries, maps one-to-many, many-to-many and one-to-one relationships.
   It also syncs relationships where only the id is present, for example if your model is: Company -> Employee,
   and your employee has a company_id, it will try to sync using that ID instead of requiring you to provide the
   entire company object inside the employees dictionary.
   - parameter changes: The array of dictionaries used in the sync process.
   - parameter entityName: The name of the entity to be synced.
   - parameter parent: The parent of the synced items, useful if you are syncing the childs of an object, for example
   an Album has many photos, if this photos don't incldue the album's JSON object, syncing the photos JSON requires
   you to send the parent album to do the proper mapping.
   - parameter dataStack: The DATAStack instance.
   - parameter completion: The completion block, it returns an error if something in the Sync process goes wrong.
   */
  public class func changes(_ changes: [[String : AnyObject]], inEntityNamed entityName: String, parent: NSManagedObject, dataStack: DATAStack, completion: ((error: NSError?) -> Void)?) {
    dataStack.performInNewBackgroundContext { backgroundContext in
      let safeParent = parent.sync_copyInContext(backgroundContext)
      guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: backgroundContext) else { fatalError("Couldn't find entity named: \(entityName)") }
      let relationships = entity.relationships(forDestination: parent.entity)
      var predicate: Predicate? = nil

      if let firstRelationship = relationships.first {
        predicate = Predicate(format: "%K = %@", firstRelationship.name, safeParent)
      }

      self.changes(changes, inEntityNamed: entityName, predicate: predicate, parent: safeParent, inContext: backgroundContext, dataStack: dataStack, operations: .all, completion: completion)
    }
  }

  /**
   Syncs the entity using the received array of dictionaries, maps one-to-many, many-to-many and one-to-one relationships.
   It also syncs relationships where only the id is present, for example if your model is: Company -> Employee,
   and your employee has a company_id, it will try to sync using that ID instead of requiring you to provide the
   entire company object inside the employees dictionary.
   - parameter changes: The array of dictionaries used in the sync process.
   - parameter entityName: The name of the entity to be synced.
   - parameter predicate: The predicate used to filter out changes, if you want to exclude some local items to be taken in
   account in the Sync process, you just need to provide this predicate.
   - parameter parent: The parent of the synced items, useful if you are syncing the childs of an object, for example
   an Album has many photos, if this photos don't incldue the album's JSON object, syncing the photos JSON requires
   - parameter context: The context where the items will be created, in general this should be a background context.
   - parameter dataStack: The DATAStack instance.
   - parameter completion: The completion block, it returns an error if something in the Sync process goes wrong.
   */
  public class func changes(_ changes: [[String : AnyObject]], inEntityNamed entityName: String, predicate: Predicate?, parent: NSManagedObject?, inContext context: NSManagedObjectContext, dataStack: DATAStack, completion: ((error: NSError?) -> Void)?) {
    self.changes(changes, inEntityNamed: entityName, predicate: predicate, parent: parent, inContext: context, dataStack: dataStack, operations: .all, completion: completion)
  }

  public class func changes(_ changes: [[String : AnyObject]], inEntityNamed entityName: String, predicate: Predicate?, parent: NSManagedObject?, inContext context: NSManagedObjectContext, dataStack: DATAStack, operations: DATAFilterOperation, completion: ((error: NSError?) -> Void)?) {
    guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else { abort() }

    let localPrimaryKey = entity.sync_localPrimaryKey()
    let remotePrimaryKey = entity.sync_remotePrimaryKey()
    let shouldLookForParent = parent == nil && predicate == nil

    var finalPredicate = predicate
    if let parentEntity = entity.sync_parentEntity() where shouldLookForParent {
      finalPredicate = Predicate(format: "%K = nil", parentEntity.name)
    }

    if localPrimaryKey.isEmpty {
      fatalError("Local primary key not found for entity: \(entityName), add a primary key named id or mark an existing attribute using hyper.isPrimaryKey")
    }

    if remotePrimaryKey.isEmpty {
      fatalError("Remote primary key not found for entity: \(entityName), we were looking for id, if your remote ID has a different name consider using hyper.remoteKey to map to the right value")
    }

    DATAFilter.changes(changes as [AnyObject], inEntityNamed: entityName, predicate: finalPredicate, operations: operations, localPrimaryKey: localPrimaryKey, remotePrimaryKey: remotePrimaryKey, context: context, inserted: { objectJSON in
      guard let JSON = objectJSON as? [String : AnyObject] else { abort() }

      let created = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
      created.sync_fillWithDictionary(JSON, parent: parent, dataStack: dataStack, operations: operations)
    }) { objectJSON, updatedObject in
      guard let JSON = objectJSON as? [String : AnyObject] else { abort() }
      updatedObject?.sync_fillWithDictionary(JSON, parent: parent, dataStack: dataStack, operations: operations)
    }

    var syncError: NSError?
    if context.hasChanges {
      do {
        try context.save()
      } catch let error as NSError {
        syncError = error
      }
    }

    DispatchQueue.main.async {
      completion?(error: syncError)
    }
  }

  func changes(_ changes: [[String : AnyObject]], inEntityNamed entityName: String, predicate: Predicate?, parent: NSManagedObject?, inContext context: NSManagedObjectContext, dataStack: DATAStack, operations: DATAFilterOperation) {
    guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else { abort() }

    let localPrimaryKey = entity.sync_localPrimaryKey()
    let remotePrimaryKey = entity.sync_remotePrimaryKey()
    let shouldLookForParent = parent == nil && predicate == nil

    var finalPredicate = predicate
    if let parentEntity = entity.sync_parentEntity() where shouldLookForParent {
      finalPredicate = Predicate(format: "%K = nil", parentEntity.name)
    }

    if localPrimaryKey.isEmpty {
      fatalError("Local primary key not found for entity: \(entityName), add a primary key named id or mark an existing attribute using hyper.isPrimaryKey")
    }

    if remotePrimaryKey.isEmpty {
      fatalError("Remote primary key not found for entity: \(entityName), we were looking for id, if your remote ID has a different name consider using hyper.remoteKey to map to the right value")
    }

    DATAFilter.changes(changes as [AnyObject], inEntityNamed: entityName, predicate: finalPredicate, operations: operations, localPrimaryKey: localPrimaryKey, remotePrimaryKey: remotePrimaryKey, context: context, inserted: { objectJSON in
      guard self.isCancelled == false else { return }
      guard let JSON = objectJSON as? [String : AnyObject] else { abort() }

      let created = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
      created.sync_fillWithDictionary(JSON, parent: parent, dataStack: dataStack, operations: operations)
    }) { objectJSON, updatedObject in
      guard self.isCancelled == false else { return }
      guard let JSON = objectJSON as? [String : AnyObject] else { abort() }
      updatedObject?.sync_fillWithDictionary(JSON, parent: parent, dataStack: dataStack, operations: operations)
    }

    if context.hasChanges {
      if self.isCancelled {
        context.reset()
      } else {
        let _ = try? context.save()
      }
    }
  }
}
