import Foundation
import CoreData

/**
 Helps you filter insertions, deletions and updates by comparing your JSON dictionary with your Core Data local objects.
 It also provides uniquing for you locally stored objects and automatic removal of not found ones.
 */
class DATAFilter: NSObject {
    struct Operation: OptionSet {
        let rawValue: Int

        init(rawValue: Int) {
            self.rawValue = rawValue
        }

        static let Insert = Operation(rawValue: 1 << 0)
        static let Update = Operation(rawValue: 1 << 1)
        static let Delete = Operation(rawValue: 1 << 2)
        static let All: Operation = [.Insert, .Update, .Delete]
    }

    class func changes(_ changes: [[String: Any]],
                       inEntityNamed entityName: String,
                       localPrimaryKey: String,
                       remotePrimaryKey: String,
                       context: NSManagedObjectContext,
                       inserted: (_ json: [String: Any]) -> Void,
                       updated: (_ json: [String: Any], _ updatedObject: NSManagedObject) -> Void) {
        self.changes(changes, inEntityNamed: entityName, predicate: nil, operations: .All, localPrimaryKey: localPrimaryKey, remotePrimaryKey: remotePrimaryKey, context: context, inserted: inserted, updated: updated)
    }

    class func changes(_ changes: [[String: Any]],
                       inEntityNamed entityName: String,
                       predicate: NSPredicate?,
                       operations: Operation,
                       localPrimaryKey: String,
                       remotePrimaryKey: String,
                       context: NSManagedObjectContext,
                       inserted: (_ json: [String: Any]) -> Void,
                       updated: (_ json: [String: Any], _ updatedObject: NSManagedObject) -> Void) {
        // `DATAObjectIDs.objectIDsInEntityNamed` also deletes all objects that don't have a primary key or that have the same primary key already found in the context
        let primaryKeysAndObjectIDs = context.managedObjectIDs(in: entityName, usingAsKey: localPrimaryKey, predicate: predicate) as [NSObject: NSManagedObjectID]
        let localPrimaryKeys = Array(primaryKeysAndObjectIDs.keys)
        let remotePrimaryKeys = changes.map { $0[remotePrimaryKey] }
        let remotePrimaryKeysWithoutNils = (remotePrimaryKeys.filter { (($0 as? NSObject) != NSNull()) && ($0 != nil) } as! [NSObject?]) as! [NSObject]

        var remotePrimaryKeysAndChanges = [NSObject: [String: Any]]()
        for (primaryKey, change) in zip(remotePrimaryKeysWithoutNils, changes) {
            remotePrimaryKeysAndChanges[primaryKey] = change
        }

        var intersection = Set(remotePrimaryKeysWithoutNils)
        intersection.formIntersection(Set(localPrimaryKeys))
        let updatedObjectIDs = Array(intersection)

        var deletedObjectIDs = localPrimaryKeys
        deletedObjectIDs = deletedObjectIDs.filter { value in
            !remotePrimaryKeysWithoutNils.contains { $0.isEqual(value) }
        }

        var insertedObjectIDs = remotePrimaryKeysWithoutNils
        insertedObjectIDs = insertedObjectIDs.filter { value in
            !localPrimaryKeys.contains { $0.isEqual(value) }
        }

        if operations.contains(.Delete) {
            for fetchedID in deletedObjectIDs {
                let objectID = primaryKeysAndObjectIDs[fetchedID]!
                let object = context.object(with: objectID)
                context.delete(object)
            }
        }

        if operations.contains(.Insert) {
            for fetchedID in insertedObjectIDs {
                let objectDictionary = remotePrimaryKeysAndChanges[fetchedID]!
                inserted(objectDictionary)
            }
        }

        if operations.contains(.Update) {
            for fetchedID in updatedObjectIDs {
                let JSON = remotePrimaryKeysAndChanges[fetchedID]!
                let objectID = primaryKeysAndObjectIDs[fetchedID]!
                let object = context.object(with: objectID)
                updated(JSON, object)
            }
        }
    }
}
