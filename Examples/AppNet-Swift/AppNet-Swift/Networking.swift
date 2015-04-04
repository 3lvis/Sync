import UIKit

class Networking: NSObject {
    let SYNCAppNetURL = "https://api.app.net/posts/stream/global"
    let SYNCReloadTableNotification = "SYNCReloadTableNotification"

    let dataStack: DATAStack!

    required init(dataStack: DATAStack) {
        super.init()
        self.dataStack = dataStack
    }

    func fetchNewContent() {
        let urlAppNet = NSURL(string: SYNCAppNetURL)
        let request = NSURLRequest(URL:urlAppNet!)
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) { (var response: NSURLResponse!, var data: NSData!, var error: NSError!) -> Void in
            if ((error) != nil) {
                let alertController = UIAlertController(title: "Ooops!", message: "There was a connection error. \(error)", preferredStyle: UIAlertControllerStyle.Alert)
                let alertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                    alertController.dismissViewControllerAnimated(true, completion: nil)
                })

                alertController.addAction(alertAction)
            } else {
                let serializationJSON: AnyObject! = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil)

                Sync.changes(serializationJSON.valueForKey("data") as NSArray, inEntityNamed: "Data", dataStack: self.dataStack, completion: { (NSError) -> Void in
                    NSNotificationCenter.defaultCenter().postNotificationName(self.SYNCReloadTableNotification, object: nil)
                })
            }
        }
    }
}
