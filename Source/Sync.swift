import UIKit
import CoreData

struct SyncConstants {
  static let CustomPrimaryKey = "hyper.isPrimaryKey"
  static let CustomRemoteKey = "hyper.remoteKey"
  static let DefaultLocalPrimaryKey = "remoteID"
  static let DefaultRemotePrimaryKey = "id"
}

@objc public class Sync {

  public class func changes(
    changes: [AnyObject],
    entityName: String,
    dataStack: DATAStack,
    completion: ((error: NSError?) -> Void)?) {

      self.changes(
        changes,
        entityName: entityName,
        predicate: nil,
        dataStack: dataStack,
        completion: completion)
  }

  public class func changes(
    changes: [AnyObject],
    entityName: String,
    predicate: NSPredicate?,
    dataStack: DATAStack,
    completion: ((error: NSError?) -> Void)?) {

      dataStack.performInNewBackgroundContext { (backgroundContext: NSManagedObjectContext!) in
        self.changes(
          changes,
          entityName: entityName,
          predicate: predicate,
          parent:nil,
          context: backgroundContext,
          dataStack: dataStack,
          completion: completion)
      }
  }

  public class func changes(
    changes: [AnyObject],
    entityName: String,
    parent: NSManagedObject,
    dataStack: DATAStack,
    completion: ((error: NSError?) -> Void)?) {

      dataStack.performInNewBackgroundContext { (backgroundContext: NSManagedObjectContext!) in

        let safeParent = parent.copyInContext(backgroundContext)
        let predicate = NSPredicate(format: "%K = %@", parent.entity.name!, safeParent!)

        self.changes(
          changes,
          entityName: entityName,
          predicate: predicate,
          parent:safeParent,
          context: backgroundContext,
          dataStack: dataStack,
          completion: completion)
      }
  }

  public class func changes(
    changes: [AnyObject],
    entityName: String,
    predicate: NSPredicate?,
    parent: NSManagedObject?,
    context: NSManagedObjectContext!,
    dataStack: DATAStack,
    completion: ((error: NSError?) -> Void)?) {

      let entity = NSEntityDescription.entityForName(
        entityName,
        inManagedObjectContext: context)

      DATAFilter.changes(
        changes,
        inEntityNamed: entityName,
        localKey: entity!.localKey(),
        remoteKey: entity!.remoteKey(),
        context: context,
        predicate: predicate,
        inserted: { (JSON: [NSObject : AnyObject]!) in

          let createdObject: NSManagedObject = NSEntityDescription.insertNewObjectForEntityForName(
            entityName,
            inManagedObjectContext: context) as! NSManagedObject
          createdObject.hyp_fillWithDictionary(JSON)
          createdObject.processRelationshipsUsingDictionary(
            objectDictionary: JSON,
            parent: parent,
            dataStack: dataStack)

        }, updated: { (JSON: [NSObject : AnyObject]!, updatedObject: NSManagedObject!) in

          updatedObject.hyp_fillWithDictionary(JSON)
          updatedObject.processRelationshipsUsingDictionary(
            objectDictionary: JSON,
            parent:parent,
            dataStack: dataStack)

      })

      var error: NSError?
      context.save(&error)
      if error != nil {
        println("Sync (error while saving \(entityName): \(error?.description)")
      }

      dataStack.persistWithCompletion {
        if completion != nil {
          completion!(error: error)
        }
      }
  }

  // MARK: Deprecated methods

  @availability(*, deprecated=1.0.0, message="Use Sync.changes(changes,entityName:dataStack:completion) instead.")
  public class func changes(
    changes: [AnyObject],
    inEntityName entityName: String,
    dataStack: DATAStack,
    completion: ((error: NSError?) -> Void)?) {

      self.changes(
        changes,
        entityName: entityName,
        predicate: nil,
        dataStack: dataStack,
        completion: completion)
  }

  @availability(*, deprecated=1.0.0, message="Use Sync.changes(changes,entityName:predicate:dataStack:completion) instead.")
  public class func changes(
    changes: [AnyObject],
    inEntityName entityName: String,
    predicate: NSPredicate?,
    dataStack: DATAStack,
    completion: ((error: NSError?) -> Void)?) {
      dataStack.performInNewBackgroundContext { (backgroundContext: NSManagedObjectContext!) in

        self.changes(
          changes,
          entityName: entityName,
          predicate: predicate,
          parent:nil,
          context: backgroundContext,
          dataStack: dataStack,
          completion: completion)
      }
  }

  @availability(*, deprecated=1.0.0, message="Use Sync.changes(changes,entityName:parent:dataStack:completion) instead.")
  public class func changes(
    changes: [AnyObject],
    inEntityName entityName: String,
    parent: NSManagedObject,
    dataStack: DATAStack,
    completion: ((error: NSError?) -> Void)?) {
      dataStack.performInNewBackgroundContext { (backgroundContext: NSManagedObjectContext!) in

        let safeParent = parent.copyInContext(backgroundContext)
        let predicate = NSPredicate(format: "%K = %@", parent.entity.name!, safeParent!)

        self.changes(
          changes,
          entityName: entityName,
          predicate: predicate,
          parent:safeParent,
          context: backgroundContext,
          dataStack: dataStack,
          completion: completion)
      }
  }

  @availability(*, deprecated=1.0.0, message="Use Sync.changes(changes,entityName:predicate:parent:context:dataStack:completion) instead.")
  public class func changes(
    changes: [AnyObject],
    inEntityName entityName: String,
    predicate: NSPredicate?,
    parent: NSManagedObject?,
    context: NSManagedObjectContext!,
    dataStack: DATAStack,
    completion: ((error: NSError?) -> Void)?) {
      let entity = NSEntityDescription.entityForName(entityName,
        inManagedObjectContext: context)

      DATAFilter.changes(
        changes,
        inEntityNamed: entityName,
        localKey: entity!.localKey(),
        remoteKey: entity!.remoteKey(),
        context: context,
        predicate: predicate,
        inserted: { (JSON: [NSObject : AnyObject]!) in

          let createdObject: AnyObject = NSEntityDescription.insertNewObjectForEntityForName(entityName,
            inManagedObjectContext: context)
          createdObject.hyp_fillWithDictionary(JSON)
          createdObject.processRelationshipsUsingDictionary(objectDictionary: JSON,
            parent: parent,
            dataStack: dataStack)

        }, updated: { (JSON: [NSObject : AnyObject]!, updatedObject: NSManagedObject!) in

          updatedObject.hyp_fillWithDictionary(JSON)
          updatedObject.processRelationshipsUsingDictionary(objectDictionary: JSON,
            parent:parent,
            dataStack: dataStack)

      })

      var error: NSError?
      context.save(&error)
      if error != nil {
        println("Sync (error while saving \(entityName): \(error?.description)")
      }

      dataStack.persistWithCompletion {
        if completion != nil {
          completion!(error: error)
        }
      }
  }

}
