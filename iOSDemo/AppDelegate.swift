import UIKit
import CoreData
import Sync

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    lazy var dataStack: DataStack = DataStack(modelName: "iOSDemo")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = UINavigationController(rootViewController: ViewController(dataStack: self.dataStack))
        self.window?.makeKeyAndVisible()

        return true
    }
}
