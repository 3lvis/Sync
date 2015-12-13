import UIKit
import DATAStack
import Sync

class Networking: NSObject {
    let AppNetURL = "https://api.app.net/posts/stream/global"
    let dataStack: DATAStack

    required init(dataStack: DATAStack) {
        self.dataStack = dataStack
    }

    func fetchItems(completion: (NSError?) -> Void) {
        let session = NSURLSession.sharedSession()
        let request = NSURLRequest(URL: NSURL(string: AppNetURL)!)
        session.dataTaskWithRequest(request, completionHandler: { data, response, error in
            if let data = data, json = (try? NSJSONSerialization.JSONObjectWithData(data, options: [])) as? [String: AnyObject] {
                Sync.changes(json["data"] as! Array, inEntityNamed: "Data", dataStack: self.dataStack, completion: { error in
                    completion(error)
                })
            } else {
                completion(error)
            }
        }).resume()
    }

    /*
    An example on how to properly receive notifications of changes. Includes a local "global.json" so you can modify it to try it,
    but it can easily work with your own JSON too. Please use notifications to react to changes, not to modify the returned elements
    since that would be unsafe.
    */
    func fetchLocalItems(completion: (NSError?) -> Void) {
        let url = NSURL(string: "global.json")!
        let filePath = NSBundle.mainBundle().pathForResource(url.URLByDeletingPathExtension?.absoluteString, ofType: url.pathExtension)!
        let data = NSData(contentsOfFile: filePath)!
        let json = try! NSJSONSerialization.JSONObjectWithData(data, options: []) as! [String: AnyObject]

        self.dataStack.performInNewBackgroundContext { backgroundContext in
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "changeNotification:", name: NSManagedObjectContextObjectsDidChangeNotification, object: backgroundContext)

            Sync.changes(json["data"] as! Array, inEntityNamed: "Data", predicate: nil, parent: nil, inContext: backgroundContext, dataStack: self.dataStack, completion: { error in
                NSNotificationCenter.defaultCenter().removeObserver(self, name: NSManagedObjectContextObjectsDidChangeNotification, object: nil)

                completion(error)
            })
        }
    }

    func changeNotification(notification: NSNotification) {
        let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey]
        let deletedObjects = notification.userInfo?[NSDeletedObjectsKey]
        let insertedObjects = notification.userInfo?[NSInsertedObjectsKey]

        print("updatedObjects: \(updatedObjects)")
        print("deletedObjects: \(deletedObjects)")
        print("insertedObjects: \(insertedObjects)")
    }
}
