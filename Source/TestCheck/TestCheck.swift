import Foundation

@objc public class TestCheck: NSObject {
    /**
    Method to check wheter your on testing mode or not.
    - returns: A Bool, `true` if you're on testing mode, `false` if you're not.
    */
    public static let isTesting: Bool = {
        let enviroment = NSProcessInfo.processInfo().environment
        let serviceName = enviroment["XPC_SERVICE_NAME"]
        let injectBundle = enviroment["XCInjectBundle"]
        var isRunning = (enviroment["TRAVIS"] != nil || enviroment["XCTestConfigurationFilePath"] != nil)

        if !isRunning {
            if let serviceName = serviceName {
                isRunning = (serviceName as NSString).pathExtension == "xctest"
            }
        }

        if !isRunning {
            if let injectBundle = injectBundle {
                isRunning = (injectBundle as NSString).pathExtension == "xctest"
            }
        }

        return isRunning
    }()
}
