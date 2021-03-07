import XCTest
import CoreData
import Sync

@objc class Helper: NSObject {
    class func objectsFromJSON(_ fileName: String) -> Any {
        let bundle = Bundle(for: Helper.self)
        let objects = try! JSON.from(fileName, bundle: bundle)!

        return objects
    }

    class func dataStackWithModelName(_ modelName: String) -> DataStack {
        let bundle = Bundle(for: Helper.self)
        let dataStack = DataStack(modelName: modelName, bundle: bundle, storeType: .sqLite)

        return dataStack
    }

    class func persistentStoreWithModelName(_ modelName: String) -> NSPersistentContainer {
        let momdModelURL = Bundle(for: NSPersistentContainerTests.self).url(forResource: modelName, withExtension: "momd")!
        let model = NSManagedObjectModel(contentsOf: momdModelURL)!
        let persistentContainer = NSPersistentContainer(name: modelName, managedObjectModel: model)
        try! persistentContainer.persistentStoreCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)

        return persistentContainer
    }

    class func countForEntity(_ entityName: String, inContext context: NSManagedObjectContext) -> Int {
        return self.countForEntity(entityName, predicate: nil, inContext: context)
    }

    class func countForEntity(_ entityName: String, predicate: NSPredicate?, inContext context: NSManagedObjectContext) -> Int {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.predicate = predicate
        let count = try! context.count(for: fetchRequest)

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
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        let objects = try! context.fetch(request) as? [NSManagedObject] ?? [NSManagedObject]()

        return objects
    }

    class func dataStackWithModelName(_ modelName: String, storeType: DataStackStoreType = .sqLite) -> DataStack {
        let bundle = Bundle(for: Helper.self)
        let dataStack = DataStack(modelName: modelName, bundle: bundle, storeType: storeType)
        return dataStack
    }

    class func insertEntity(_ name: String, dataStack: DataStack) -> NSManagedObject {
        let entity = NSEntityDescription.entity(forEntityName: name, in: dataStack.mainContext)!
        return NSManagedObject(entity: entity, insertInto: dataStack.mainContext)
    }

}
