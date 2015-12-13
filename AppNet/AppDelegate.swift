import UIKit
import CoreData
import DATAStack

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    lazy var dataStack: DATAStack = DATAStack()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        application.setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)

        let appearance = UINavigationBar.appearance()
        appearance.barTintColor = UIColor(red:0.83, green:0.43, blue:0.36, alpha:1)
        appearance.titleTextAttributes = [NSFontAttributeName : UIFont(name: "AvenirNext-DemiBold", size: 20)!,
            NSForegroundColorAttributeName : UIColor.whiteColor()]

        window = UIWindow(frame: UIScreen.mainScreen().bounds)

        let initialViewController = ViewController(dataStack: dataStack)

        window?.rootViewController = UINavigationController(rootViewController: initialViewController)
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

