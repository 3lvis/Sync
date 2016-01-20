import CoreData
import NSEntityDescription_SYNCPrimaryKey
import DATAFilter
import NSManagedObject_HYPPropertyMapper
import DATAStack

@objc public class Sync: NSObject {
    public class func changes(changes: [AnyObject], inEntityNamed entityName: String, parent: NSManagedObject, dataStack: DATAStack, completion: Void -> Void) {
        dataStack.performInNewBackgroundContext { backgroundContext in
//            let safeParent = parent.sync_copyInContext(backgroundContext)
//            let entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: backgroundContext)!
//            let relationships = entity.relationshipsWithDestinationEntity(parent.entity)
//            let predicate = NSPredicate(format: "%K = %@", relationships.first!.name, safeParent)
        }
    }

    public class func changes(changes: [AnyObject], inEntityNamed entityName: String, predicate: NSPredicate?, parent: NSManagedObject?, inContext context: NSManagedObjectContext, dataStack: DATAStack, completion: (Void -> Void)?) {
        let entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: context)!
        let localKey = entity.sync_localKey()
        let remoteKey = entity.sync_remoteKey()
        let shouldLookForParent = (parent == nil && predicate == nil)
        if shouldLookForParent {
            // let parentEntity = entity.sync_parentEntity()
            // predicate = NSPredicate(format: "%K = nil", parentEntity.name)
        }

        DATAFilter.changes(changes, inEntityNamed: entityName, predicate: predicate, operations: .All, localKey: localKey, remoteKey: remoteKey, context: context, inserted: { JSON in
            let created = NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: context)
            created.hyp_fillWithDictionary(JSON)
            // created.sync_processRelationshipsUsingDictionary(JSON, andParent: parent, dataStack: dataStack)
        }) { (JSON, updatedObject) in
            updatedObject.hyp_fillWithDictionary(JSON)
            // updatedObject.sync_processRelationshipsUsingDictionary(JSON, andParent: parent, dataStack: dataStack)
        }

        try! context.save()
        dataStack.persistWithCompletion {
            completion?()
        }
    }
}
