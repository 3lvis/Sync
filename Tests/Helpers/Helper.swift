import XCTest
import CoreData
import DATAStack
import Sync
import JSON

@objc class Helper: NSObject {
    class func objectsFromJSON(_ fileName: String) -> AnyObject {
        let bundle = Bundle(for: Helper.self)
        let objects = try! JSON.from(fileName, bundle: bundle)!

        return objects
    }

    class func dataStackWithModelName(_ modelName: String) -> DATAStack {
        let bundle = Bundle(for: Helper.self)
        let dataStack = DATAStack(modelName: modelName, bundle: bundle, storeType: .SQLite)

        return dataStack
    }

    class func countForEntity(_ entityName: String, inContext context: NSManagedObjectContext) -> Int {
        return self.countForEntity(entityName, predicate: nil, inContext: context)
    }

    class func countForEntity(_ entityName: String, predicate: NSPredicate?, inContext context: NSManagedObjectContext) -> Int {
        let fetchRequest = NSFetchRequest(entityName: entityName)
        fetchRequest.predicate = predicate
        #if swift(>=2.3)
            let count = try! context.countForFetchRequest(fetchRequest)
        #else
            var error: NSError?
            let count = context.countForFetchRequest(fetchRequest, error: &error)
            if let error = error {
                print("Count error: %@", error.description)
            }
        #endif

        return count
    }

    class func fetchEntity(_ entityName: String, inContext context: NSManagedObjectContext) -> [NSManagedObject] {
        return self.fetchEntity(entityName, predicate: nil, sortDescriptors: nil, inContext: context)
    }

    class func fetchEntity(_ entityName: String, predicate: NSPredicate?, inContext context: NSManagedObjectContext) -> [NSManagedObject] {
        return self.fetchEntity(entityName, predicate: predicate, sortDescriptors: nil, inContext: context)
    }

    class func fetchEntity(_ entityName: String, sortDescriptors: [NSSortDescriptor]?, inContext context: NSManagedObjectContext) -> [NSManagedObject] {
        return self.fetchEntity(entityName, predicate: nil, sortDescriptors: sortDescriptors, inContext: context)
    }

    class func fetchEntity(_ entityName: String, predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?, inContext context: NSManagedObjectContext) -> [NSManagedObject] {
        let request = NSFetchRequest(entityName: entityName)
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        let objects = try! context.fetch(request) as? [NSManagedObject] ?? [NSManagedObject]()

        return objects
    }
}
