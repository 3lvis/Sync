import UIKit

class Networking {

  struct Constanst {
    static let SYNCAppNetURL = "https://api.app.net/posts/stream/global"
    static let SYNCReloadTableNotification = "SYNCReloadTableNotification"
  }

  let dataStack: DATAStack

  required init(dataStack: DATAStack) {
    self.dataStack = dataStack
  }

  func fetchItems(completion: (NSError?) -> Void) {

    let urlAppNet = NSURL(string: Constanst.SYNCAppNetURL)
    let request = NSURLRequest(URL: urlAppNet!)
    let operationQueue = NSOperationQueue()

    NSURLConnection.sendAsynchronousRequest(request, queue: operationQueue) { [unowned self] _, data, error in
      if let data = data, json = NSJSONSerialization.JSONObjectWithData(data,
        options: NSJSONReadingOptions.MutableContainers,
        error: nil) as? Dictionary<String, AnyObject> {
          Sync.changes(json["data"] as! Array,
            inEntityNamed: "Data",
            dataStack: self.dataStack,
            completion: { error in
              completion(error)
          })
      } else {
        completion(error)
      }
    }
  }
}
