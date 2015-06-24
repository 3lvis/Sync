import Foundation
import XCTest
import DATAStack
import NSJSONSerialization_ANDYJSONFile

class Tests: XCTestCase {
    func dropSQLiteFileForModelNamed(modelName: String) {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask) as Array
        let url = urls.last as! NSURL
        let path = modelName + ".sqlite"
        let storeURL = url.URLByAppendingPathComponent(path)
        let fileManager = NSFileManager.defaultManager()

        if let storePath = storeURL.path {
            if fileManager.fileExistsAtPath(storePath) {
                fileManager.removeItemAtURL(storeURL, error: nil)
            } else {
                println("File at path \(storePath) not found")
            }
        } else {
            println("Path for storeURL \(storeURL) not found")
        }
    }

    func dataStackWithModelName(modelName: String) -> DATAStack {
        self.dropSQLiteFileForModelNamed(modelName)

        let dataStack = DATAStack(
            modelName: modelName,
            bundle: NSBundle(forClass: self.classForCoder),
            storeType: .SQLiteStoreType)

        return dataStack
    }

    func objectsFromJSON(fileName: String) -> [AnyObject] {
        let bundle = NSBundle(forClass: self.classForCoder)
        let array = NSJSONSerialization.JSONObjectWithContentsOfFile(fileName, inBundle: bundle) as! [AnyObject]

        return array
    }

    func testUpdate() {
        let objectsA = self.objectsFromJSON("users_a.json")

        let dataStack = self.dataStackWithModelName("Contacts")

        Sync.changes(
            objectsA,
            inEntityNamed: "User",
            dataStack: dataStack,
            completion: nil)

        
    }
}
