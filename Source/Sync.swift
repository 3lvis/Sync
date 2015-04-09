import UIKit
import CoreData

let CustomPrimaryKey = "hyper.isPrimaryKey"
let CustomRemoteKey = "hyper.remoteKey"

private extension NSEntityDescription {

    func sync_localKey() {
        var localKey: String?

        for (key, attributedDescription) in self.propertiesByName {
            if let userInfo = attributedDescription.userInfo {
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
