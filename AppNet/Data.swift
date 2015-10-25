import Foundation
import CoreData

@objc(Data)

class Data: NSManagedObject {

  @NSManaged var text: String
  @NSManaged var remoteID: String
  @NSManaged var createdAt: NSTimeInterval
  @NSManaged var user: User

}
