import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var initialViewController: ViewController!
    var dataStack: DATAStack? {
        get {
            return DATAStack(modelName: "AppNet_Swift")
        }
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)
        UINavigationBar.appearance().barTintColor = UIColor(red:0.83, green:0.43, blue:0.36, alpha:1)
        UINavigationBar.appearance().titleTextAttributes = [NSFontAttributeName : UIFont(name: "AvenirNext-DemiBold", size: 20)!, NSForegroundColorAttributeName : UIColor.whiteColor()]

        window = UIWindow(frame: UIScreen.mainScreen().bounds)

        initialViewController = ViewController(dataStack: dataStack!)
        var navigationController = UINavigationController(rootViewController: initialViewController)

        window!.rootViewController = navigationController
        window!.makeKeyAndVisible()

        return true
    }

    func applicationWillTerminate(application: UIApplication) {
        dataStack!.persistWithCompletion(nil)
    }
}

