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

  func fetchNewContent(completion: () -> Void) {

    let urlAppNet = must_unwrap(NSURL(string: Constanst.SYNCAppNetURL))
    let request = NSURLRequest(URL: urlAppNet)
    let operationQueue = NSOperationQueue()

    NSURLConnection.sendAsynchronousRequest(request, queue: operationQueue) { [unowned self] _, data, error in
      if error != nil {
        let alertController = UIAlertController(title: "Ooops!", message: "There was a connection error. \(error)", preferredStyle: .Alert)
        let alertAction = UIAlertAction(title: "OK", style: .Default, handler: { action in
          alertController.dismissViewControllerAnimated(true, completion: nil)
        })

        alertController.addAction(alertAction)
      } else {
        if let json = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) as? Dictionary<String, AnyObject> {
          Sync.changes(json["data"] as Array, inEntityNamed: "Data", dataStack: self.dataStack, completion: { error in
            completion()
          })
        }
      }
    }
  }
}

func must_unwrap <T>(x: T?) -> T  {
  if let x = x {
    return x
  }
  assertionFailure("Can't unwrap optional")
}
