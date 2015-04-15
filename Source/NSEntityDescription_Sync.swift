import Foundation

extension NSEntityDescription {

  func primaryKeyAttribute() -> NSAttributeDescription? {
    var primaryKeyAttribute: NSAttributeDescription?

    for (key, attributedDescription) in self.propertiesByName {
      if let
        userInfo: Dictionary = attributedDescription.userInfo,
        customPrimaryKey = userInfo[SyncConstants.CustomPrimaryKey] as? String
        where customPrimaryKey == "YES" {
          primaryKeyAttribute = attributedDescription as? NSAttributeDescription
      }

      if key == SyncConstants.DefaultLocalPrimaryKey {
        primaryKeyAttribute = attributedDescription as? NSAttributeDescription
      }
    }

    return primaryKeyAttribute
  }

  func localKey() -> String {
    var localKey = SyncConstants.DefaultLocalPrimaryKey

    if let primaryKeyAttribute = self.primaryKeyAttribute() {
      localKey = primaryKeyAttribute.name
    }

    return localKey
  }

  func remoteKey() -> String {
    var remoteKey = SyncConstants.DefaultRemotePrimaryKey
    let localKey = self.localKey()

    if localKey != SyncConstants.DefaultLocalPrimaryKey {
      remoteKey = localKey.hyp_remoteString()
    }

    return remoteKey
  }
}
