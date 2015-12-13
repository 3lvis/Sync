import UIKit
import DATAStack
import Sync

class Networking {
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
                Sync.changes(json["data"] as! Array,
                    inEntityNamed: "Data",
                    dataStack: self.dataStack,
                    completion: { error in
                        completion(error)
                })
            } else {
                completion(error)
            }
        }).resume()
    }
}
