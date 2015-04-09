import UIKit
import CoreData

let SyncCustomPrimaryKey = "hyper.isPrimaryKey"
let SyncCustomRemoteKey = "hyper.remoteKey"

private extension NSEntityDescription {

    func sync_localKey() {
        var localKey: String?

        for (key, attributedDescription) in self.propertiesByName {
            if let userInfo: Dictionary = attributedDescription.userInfo {
                if let customPrimaryKey = userInfo[SyncCustomPrimaryKey] as? String {
                    if customPrimaryKey == "YES" {
                        localKey = key as? String
                    }
                }
            }
        }

    }

}

public extension NSManagedObject {

    private func sync_copyInContext(context: NSManagedObjectContext) -> NSManagedObject? {
        let entity = NSEntityDescription.entityForName(self.entity.name!,
            inManagedObjectContext: context)

            return nil
    }

}
