import CoreData
import NSEntityDescription_SYNCPrimaryKey
import DATAFilter
import NSManagedObject_HYPPropertyMapper
import DATAStack

@objc public class Sync: NSObject {
    public class func changes(changes: [[String : AnyObject]], inEntityNamed entityName: String, dataStack: DATAStack, completion: ((error: NSError?) -> Void)?) {
        self.changes(changes, inEntityNamed: entityName, predicate: nil, dataStack: dataStack, completion: completion)
    }

    public class func changes(changes: [[String : AnyObject]], inEntityNamed entityName: String, predicate: NSPredicate?, dataStack: DATAStack, completion: ((error: NSError?) -> Void)?) {
        dataStack.performInNewBackgroundContext { backgroundContext in
            self.changes(changes, inEntityNamed: entityName, predicate: predicate, parent: nil, inContext: backgroundContext, dataStack: dataStack, completion: completion)
        }
    }

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

    public class func changes(changes: [[String : AnyObject]], inEntityNamed entityName: String, var predicate: NSPredicate?, parent: NSManagedObject?, inContext context: NSManagedObjectContext, dataStack: DATAStack, completion: ((error: NSError?) -> Void)?) {
        let entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: context)!
        let localKey = entity.sync_localKey()
        let remoteKey = entity.sync_remoteKey()
        let shouldLookForParent = (parent == nil && predicate == nil)
        if shouldLookForParent {
            if let parentEntity = entity.sync_parentEntity() {
                predicate = NSPredicate(format: "%K = nil", parentEntity.name)
            }
        }

        DATAFilter.changes(changes as [AnyObject], inEntityNamed: entityName, predicate: predicate, operations: [.All], localKey: localKey, remoteKey: remoteKey, context: context, inserted: { objectJSON in
            let created = NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: context)
            created.hyp_fillWithDictionary(objectJSON)
            created.sync_processRelationshipsUsingDictionary(objectJSON, parent: parent, dataStack: dataStack)
            }) { objectJSON, updatedObject in
                updatedObject.hyp_fillWithDictionary(objectJSON)
                updatedObject.sync_processRelationshipsUsingDictionary(objectJSON, parent: parent, dataStack: dataStack)
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
