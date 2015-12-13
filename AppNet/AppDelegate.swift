import UIKit
import CoreData
import DATAStack

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    lazy var dataStack: DATAStack = DATAStack()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window?.rootViewController = UINavigationController(rootViewController: ViewController(dataStack: dataStack))
        window?.makeKeyAndVisible()
        return true
    }

    func applicationDidEnterBackground(application: UIApplication) {
        self.dataStack.persistWithCompletion(nil)
    }

    func applicationWillTerminate(application: UIApplication) {
        self.dataStack.persistWithCompletion(nil)
    }
}

