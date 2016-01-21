import Foundation
import CoreData

@objc(User)
class User: NSManagedObject {
    @NSManaged var name: String
    @NSManaged var remoteID: String
    @NSManaged var username: String
    @NSManaged var data: NSSet
    
}
