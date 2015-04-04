import Foundation
import CoreData

class Data: NSManagedObject {

    @NSManaged var createdAt: NSDate
    @NSManaged var remoteID: String
    @NSManaged var text: String
    @NSManaged var user: User

}
