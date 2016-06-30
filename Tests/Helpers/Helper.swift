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

    class func dataStack(_ modelName: String) -> DATAStack {
        let bundle = Bundle(for: Helper.self)
        let dataStack = DATAStack(modelName: modelName, bundle: bundle, storeType: .sqLite)

        return dataStack
    }

    class func countForEntity(_ entityName: String, inContext context: NSManagedObjectContext) -> Int {
        return self.count(entityName, predicate: nil, inContext: context)
    }

    class func count(_ entityName: String, predicate: Predicate?, inContext context: NSManagedObjectContext) -> Int {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.predicate = predicate
        let count = try! context.count(for: fetchRequest)

        return count
    }

    class func fetchEntity(_ entityName: String, inContext context: NSManagedObjectContext) -> [NSManagedObject] {
        return self.fetchEntity(entityName, predicate: nil, sortDescriptors: nil, inContext: context)
    }

    class func fetchEntity(_ entityName: String, predicate: Predicate?, inContext context: NSManagedObjectContext) -> [NSManagedObject] {
        return self.fetchEntity(entityName, predicate: predicate, sortDescriptors: nil, inContext: context)
    }

    class func fetchEntity(_ entityName: String, sortDescriptors: [SortDescriptor]?, inContext context: NSManagedObjectContext) -> [NSManagedObject] {
        return self.fetchEntity(entityName, predicate: nil, sortDescriptors: sortDescriptors, inContext: context)
    }

    class func fetchEntity(_ entityName: String, predicate: Predicate?, sortDescriptors: [SortDescriptor]?, inContext context: NSManagedObjectContext) -> [NSManagedObject] {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        let objects = try! context.fetch(request) as? [NSManagedObject] ?? [NSManagedObject]()

        return objects
    }
}
