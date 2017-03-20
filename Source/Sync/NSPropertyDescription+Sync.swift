import CoreData

extension NSPropertyDescription {
    var customKey: String? {
        var keyName = userInfo?[SyncCustomRemoteKey] as? String

        if keyName == nil {
            keyName = userInfo?[SyncCompatibilityCustomRemoteKey] as? String
        }

        return keyName
    }
}
