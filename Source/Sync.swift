import CoreData
import NSEntityDescription_SYNCPrimaryKey
import DATAFilter
import NSManagedObject_HYPPropertyMapper
import DATAStack

@objc public class Sync: NSObject {
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
  public class func changes(changes: [[String : AnyObject]], inEntityNamed entityName: String, dataStack: DATAStack, completion: ((error: NSError?) -> Void)?) {
    self.changes(changes, inEntityNamed: entityName, predicate: nil, dataStack: dataStack, completion: completion)
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
  public class func changes(changes: [[String : AnyObject]], inEntityNamed entityName: String, predicate: NSPredicate?, dataStack: DATAStack, completion: ((error: NSError?) -> Void)?) {
    dataStack.performInNewBackgroundContext { backgroundContext in
      self.changes(changes, inEntityNamed: entityName, predicate: predicate, parent: nil, inContext: backgroundContext, dataStack: dataStack, completion: completion)
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
  public class func changes(changes: [[String : AnyObject]], inEntityNamed entityName: String, parent: NSManagedObject, dataStack: DATAStack, completion: ((error: NSError?) -> Void)?) {
    dataStack.performInNewBackgroundContext { backgroundContext in
      let safeParent = parent.sync_copyInContext(backgroundContext)
      let entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: backgroundContext)!
      let relationships = entity.relationshipsWithDestinationEntity(parent.entity)
      var predicate: NSPredicate? = nil

      if let firstRelationship = relationships.first {
        predicate = NSPredicate(format: "%K = %@", firstRelationship.name, safeParent)
      }

      self.changes(changes, inEntityNamed: entityName, predicate: predicate, parent: safeParent, inContext: backgroundContext, dataStack: dataStack, completion: completion)
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
  public class func changes(changes: [[String : AnyObject]], inEntityNamed entityName: String, predicate: NSPredicate?, parent: NSManagedObject?, inContext context: NSManagedObjectContext, dataStack: DATAStack, completion: ((error: NSError?) -> Void)?) {
    guard let entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: context) else { abort() }

    let localKey = entity.sync_localKey()
    let remoteKey = entity.sync_remoteKey()
    let shouldLookForParent = parent == nil && predicate == nil

    var finalPredicate = predicate
    if let parentEntity = entity.sync_parentEntity() where shouldLookForParent {
      finalPredicate = NSPredicate(format: "%K = nil", parentEntity.name)
    }

    if localKey.isEmpty {
      fatalError("Local primary key not found for entity: \(entityName), add a primary key named remoteID or mark an existing attribute using hyper.isPrimaryKey")
    }

    if remoteKey.isEmpty {
      fatalError("Remote primary key not found for entity: \(entityName), we were looking for id, if your remote ID has a different name consider using hyper.remoteKey to map to the right value")
    }

    DATAFilter.changes(changes as [AnyObject], inEntityNamed: entityName, predicate: finalPredicate, operations: [.All], localKey: localKey, remoteKey: remoteKey, context: context, inserted: { objectJSON in
      guard let JSON = objectJSON as? [String : AnyObject] else { abort() }

      let created = NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: context)
      created.sync_fillWithDictionary(JSON, parent: parent, dataStack: dataStack)
      }) { objectJSON, updatedObject in
        guard let JSON = objectJSON as? [String : AnyObject] else { abort() }
        updatedObject.sync_fillWithDictionary(JSON, parent: parent, dataStack: dataStack)
    }

    var syncError: NSError?
    do {
      try context.save()
    } catch let error as NSError {
      syncError = error
    }

    dataStack.persistWithCompletion {
      completion?(error: syncError)
    }
  }
}
