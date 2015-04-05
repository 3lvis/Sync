import UIKit

class Networking: NSObject {
  let SYNCAppNetURL = "https://api.app.net/posts/stream/global"
  let SYNCReloadTableNotification = "SYNCReloadTableNotification"

  let dataStack: DATAStack

  required init(dataStack: DATAStack) {
      self.dataStack = dataStack
      super.init()
  }

  func fetchNewContent() {
      let urlAppNet = NSURL(string: SYNCAppNetURL)
      let request = NSURLRequest(URL: urlAppNet!)
      let operationQueue = NSOperationQueue()
      NSURLConnection.sendAsynchronousRequest(request, queue: operationQueue) { (_, data, error) in
          if error != nil {
              let alertController = UIAlertController(title: "Ooops!", message: "There was a connection error. \(error)", preferredStyle: .Alert)
              let alertAction = UIAlertAction(title: "OK", style: .Default, handler: { action in
                  alertController.dismissViewControllerAnimated(true, completion: nil)
              })

              alertController.addAction(alertAction)
          } else {
              let serializationJSON: AnyObject! = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil)

              Sync.changes(serializationJSON.valueForKey("data") as NSArray, inEntityNamed: "Data", dataStack: self.dataStack, completion: { [unowned self] error in
                  
              })
          }
      }
  }
}
