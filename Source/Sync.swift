import UIKit
import CoreData
import NSString_HYPNetworking

let CustomPrimaryKey = "hyper.isPrimaryKey"
let CustomRemoteKey = "hyper.remoteKey"
let DefaultLocalPrimaryKey = "remoteID"
let DefaultRemotePrimaryKey = "id"

private extension NSEntityDescription {

  func sync_localKey() -> String {
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

    if !(localKey != nil) {
      localKey = DefaultLocalPrimaryKey
    }

    return localKey!
  }

  func sync_remoteKey() -> String {
    var remoteKey: String?
    let localKey = sync_localKey()

    if localKey == remoteKey {
      remoteKey = DefaultRemotePrimaryKey
    } else {
      remoteKey = localKey.hyp_remoteString()
    }

    return remoteKey!
  }

}

public extension NSManagedObject {

  private func sync_copyInContext(context: NSManagedObjectContext) -> NSManagedObject? {
    let entity = NSEntityDescription.entityForName(self.entity.name!,
        inManagedObjectContext: context)

    return nil
  }
}
