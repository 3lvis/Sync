import CoreData
import NSEntityDescription_SYNCPrimaryKey
import DATAStack

public extension NSManagedObject {
    public func sync_copyInContext(context: NSManagedObjectContext) -> NSManagedObject {
        let entity = NSEntityDescription.entityForName(self.entity.name!, inManagedObjectContext: context)!
        let localKey = entity.sync_localKey()
        let remoteID = self.valueForKey(localKey)

        return context.sync_safeObject(self.entity.name!, remoteID: remoteID, parent: nil, parentRelationshipName: nil)
    }

    public func sync_processRelationshipsUsingDictionary(objectDictionary: NSDictionary, parent: NSManagedObject, dataStack: DATAStack) {

    }

    public func sync_processToManyRelationship(relationship: NSRelationshipDescription, objectDictionary: NSDictionary, parent: NSManagedObject, dataStack: DATAStack) {
        
    }

    public func sync_processToOneRelationship(relationship: NSRelationshipDescription, objectDictionary: NSDictionary, parent: NSDictionary, dataStack: DATAStack) {

    }

    public func sync_processIDRelationship(relationship: NSRelationshipDescription, remoteID: NSNumber, parent: NSManagedObject, dataStack: DATAStack) {

    }
}
