import CoreData
import NSEntityDescription_SYNCPrimaryKey

public extension NSManagedObject {
    public func sync_copyInContext(context: NSManagedObjectContext) -> NSManagedObject {
        let entity = NSEntityDescription.entityForName(self.entity.name!, inManagedObjectContext: context)!
        let localKey = entity.sync_localKey()
        let remoteID = self.valueForKey(localKey)

        return context.sync_safeObject(self.entity.name!, remoteID: remoteID, parent: nil, parentRelationshipName: nil)
    }
}
