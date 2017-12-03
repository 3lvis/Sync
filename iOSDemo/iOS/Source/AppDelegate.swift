import UIKit

@UIApplicationMain
class AppDelegate: UIResponder {
    var window: UIWindow?

    lazy var fetcher: Fetcher = {
        let fetcher = Fetcher()

        return fetcher
    }()
}

extension AppDelegate: UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        guard let window = self.window else { fatalError("Window not found") }

        let navigationController = UINavigationController(rootViewController: ItemsController(fetcher: self.fetcher))
        window.rootViewController = navigationController
        window.makeKeyAndVisible()

        return true
    }
}
