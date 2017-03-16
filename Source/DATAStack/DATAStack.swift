import Foundation
import CoreData

@objc public enum DATAStackStoreType: Int {
    case inMemory, sqLite

    var type: String {
        switch self {
        case .inMemory:
            return NSInMemoryStoreType
        case .sqLite:
            return NSSQLiteStoreType
        }
    }
}

@objc public class DATAStack: NSObject {
    private var storeType = DATAStackStoreType.sqLite

    private var storeName: String?

    private var modelName = ""

    private var modelBundle = Bundle.main

    private var model: NSManagedObjectModel

    private var containerURL = URL.directoryURL()

    private var _mainContext: NSManagedObjectContext?

    /**
     The context for the main queue. Please do not use this to mutate data, use `performInNewBackgroundContext`
     instead.
     */
    public lazy var mainContext: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.undoManager = nil
        context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        context.persistentStoreCoordinator = self.persistentStoreCoordinator

        NotificationCenter.default.addObserver(self, selector: #selector(DATAStack.mainContextDidSave(_:)), name: .NSManagedObjectContextDidSave, object: context)

        return context
    }()

    /**
     The context for the main queue. Please do not use this to mutate data, use `performBackgroundTask`
     instead.
     */
    public var viewContext: NSManagedObjectContext {
        return self.mainContext
    }

    private lazy var writerContext: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: DATAStack.backgroundConcurrencyType())
        context.undoManager = nil
        context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        context.persistentStoreCoordinator = self.persistentStoreCoordinator

        return context
    }()

    private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.model)
        try! persistentStoreCoordinator.addPersistentStore(storeType: self.storeType, bundle: self.modelBundle, modelName: self.modelName, storeName: self.storeName, containerURL: self.containerURL)

        return persistentStoreCoordinator
    }()

    private lazy var disposablePersistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let model = NSManagedObjectModel(bundle: self.modelBundle, name: self.modelName)
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        try! persistentStoreCoordinator.addPersistentStore(storeType: .inMemory, bundle: self.modelBundle, modelName: self.modelName, storeName: self.storeName, containerURL: self.containerURL)

        return persistentStoreCoordinator
    }()

    /**
     Initializes a DATAStack using the bundle name as the model name, so if your target is called ModernApp,
     it will look for a ModernApp.xcdatamodeld.
     */
    public override init() {
        let bundle = Bundle.main
        if let bundleName = bundle.infoDictionary?["CFBundleName"] as? String {
            self.modelName = bundleName
        }
        self.model = NSManagedObjectModel(bundle: self.modelBundle, name: self.modelName)

        super.init()
    }

    /**
     Initializes a DATAStack using the provided model name.
     - parameter modelName: The name of your Core Data model (xcdatamodeld).
     */
    public init(modelName: String) {
        self.modelName = modelName
        self.model = NSManagedObjectModel(bundle: self.modelBundle, name: self.modelName)

        super.init()
    }

    /**
     Initializes a DATAStack using the provided model name, bundle and storeType.
     - parameter modelName: The name of your Core Data model (xcdatamodeld).
     - parameter storeType: The store type to be used, you have .InMemory and .SQLite, the first one is memory
     based and doesn't save to disk, while the second one creates a .sqlite file and stores things there.
     */
    public init(modelName: String, storeType: DATAStackStoreType) {
        self.modelName = modelName
        self.storeType = storeType
        self.model = NSManagedObjectModel(bundle: self.modelBundle, name: self.modelName)

        super.init()
    }

    /**
     Initializes a DATAStack using the provided model name, bundle and storeType.
     - parameter modelName: The name of your Core Data model (xcdatamodeld).
     - parameter bundle: The bundle where your Core Data model is located, normally your Core Data model is in
     the main bundle but when using unit tests sometimes your Core Data model could be located where your tests
     are located.
     - parameter storeType: The store type to be used, you have .InMemory and .SQLite, the first one is memory
     based and doesn't save to disk, while the second one creates a .sqlite file and stores things there.
     */
    public init(modelName: String, bundle: Bundle, storeType: DATAStackStoreType) {
        self.modelName = modelName
        self.modelBundle = bundle
        self.storeType = storeType
        self.model = NSManagedObjectModel(bundle: self.modelBundle, name: self.modelName)

        super.init()
    }

    /**
     Initializes a DATAStack using the provided model name, bundle, storeType and store name.
     - parameter modelName: The name of your Core Data model (xcdatamodeld).
     - parameter bundle: The bundle where your Core Data model is located, normally your Core Data model is in
     the main bundle but when using unit tests sometimes your Core Data model could be located where your tests
     are located.
     - parameter storeType: The store type to be used, you have .InMemory and .SQLite, the first one is memory
     based and doesn't save to disk, while the second one creates a .sqlite file and stores things there.
     - parameter storeName: Normally your file would be named as your model name is named, so if your model
     name is AwesomeApp then the .sqlite file will be named AwesomeApp.sqlite, this attribute allows your to
     change that.
     */
    public init(modelName: String, bundle: Bundle, storeType: DATAStackStoreType, storeName: String) {
        self.modelName = modelName
        self.modelBundle = bundle
        self.storeType = storeType
        self.storeName = storeName
        self.model = NSManagedObjectModel(bundle: self.modelBundle, name: self.modelName)

        super.init()
    }

    /**
     Initializes a DATAStack using the provided model name, bundle, storeType and store name.
     - parameter modelName: The name of your Core Data model (xcdatamodeld).
     - parameter bundle: The bundle where your Core Data model is located, normally your Core Data model is in
     the main bundle but when using unit tests sometimes your Core Data model could be located where your tests
     are located.
     - parameter storeType: The store type to be used, you have .InMemory and .SQLite, the first one is memory
     based and doesn't save to disk, while the second one creates a .sqlite file and stores things there.
     - parameter storeName: Normally your file would be named as your model name is named, so if your model
     name is AwesomeApp then the .sqlite file will be named AwesomeApp.sqlite, this attribute allows your to
     change that.
     - parameter containerURL: The container URL for the sqlite file when a store type of SQLite is used.
     */
    public init(modelName: String, bundle: Bundle, storeType: DATAStackStoreType, storeName: String, containerURL: URL) {
        self.modelName = modelName
        self.modelBundle = bundle
        self.storeType = storeType
        self.storeName = storeName
        self.containerURL = containerURL
        self.model = NSManagedObjectModel(bundle: self.modelBundle, name: self.modelName)

        super.init()
    }

    /**
     Initializes a DATAStack using the provided model name, bundle and storeType.
     - parameter model: The model that we'll use to set up your DATAStack.
     - parameter storeType: The store type to be used, you have .InMemory and .SQLite, the first one is memory
     based and doesn't save to disk, while the second one creates a .sqlite file and stores things there.
     */
    public init(model: NSManagedObjectModel, storeType: DATAStackStoreType) {
        self.model = model
        self.storeType = storeType

        let bundle = Bundle.main
        if let bundleName = bundle.infoDictionary?["CFBundleName"] as? String {
            self.storeName = bundleName
        }

        super.init()
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .NSManagedObjectContextWillSave, object: nil)
        NotificationCenter.default.removeObserver(self, name: .NSManagedObjectContextDidSave, object: nil)
    }

    /**
     Returns a new main context that is detached from saving to disk.
     */
    public func newDisposableMainContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = self.disposablePersistentStoreCoordinator
        context.undoManager = nil

        NotificationCenter.default.addObserver(self, selector: #selector(DATAStack.newDisposableMainContextWillSave(_:)), name: NSNotification.Name.NSManagedObjectContextWillSave, object: context)

        return context
    }

    /**
     Returns a background context perfect for data mutability operations. Make sure to never use it on the main thread. Use `performBlock` or `performBlockAndWait` to use it.
     Saving to this context doesn't merge with the main thread. This context is specially useful to run operations that don't block the main thread. To refresh your main thread objects for
     example when using a NSFetchedResultsController use `try self.fetchedResultsController.performFetch()`.
     */
    public func newNonMergingBackgroundContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: DATAStack.backgroundConcurrencyType())
        context.persistentStoreCoordinator = self.persistentStoreCoordinator
        context.undoManager = nil
        context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy

        return context
    }

    /**
     Returns a background context perfect for data mutability operations. Make sure to never use it on the main thread. Use `performBlock` or `performBlockAndWait` to use it.
     */
    public func newBackgroundContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: DATAStack.backgroundConcurrencyType())
        context.persistentStoreCoordinator = self.persistentStoreCoordinator
        context.undoManager = nil
        context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy

        NotificationCenter.default.addObserver(self, selector: #selector(DATAStack.backgroundContextDidSave(_:)), name: .NSManagedObjectContextDidSave, object: context)

        return context
    }

    /**
     Returns a background context perfect for data mutability operations.
     - parameter operation: The block that contains the created background context.
     */
    public func performInNewBackgroundContext(_ operation: @escaping (_ backgroundContext: NSManagedObjectContext) -> Void) {
        let context = self.newBackgroundContext()
        let contextBlock: @convention(block) () -> Void = {
            operation(context)
        }
        let blockObject: AnyObject = unsafeBitCast(contextBlock, to: AnyObject.self)
        context.perform(DATAStack.performSelectorForBackgroundContext(), with: blockObject)
    }

    /**
     Returns a background context perfect for data mutability operations.
     - parameter operation: The block that contains the created background context.
     */
    public func performBackgroundTask(operation: @escaping (_ backgroundContext: NSManagedObjectContext) -> Void) {
        self.performInNewBackgroundContext(operation)
    }

    func saveMainThread(completion: ((_ error: NSError?) -> Void)?) {
        var writerContextError: NSError?
        let writerContextBlock: @convention(block) () -> Void = {
            do {
                try self.writerContext.save()
                if TestCheck.isTesting {
                    completion?(nil)
                }
            } catch let parentError as NSError {
                writerContextError = parentError
            }
        }
        let writerContextBlockObject: AnyObject = unsafeBitCast(writerContextBlock, to: AnyObject.self)

        let mainContextBlock: @convention(block) () -> Void = {
            self.writerContext.perform(DATAStack.performSelectorForBackgroundContext(), with: writerContextBlockObject)
            DispatchQueue.main.async {
                completion?(writerContextError)
            }
        }
        let mainContextBlockObject: AnyObject = unsafeBitCast(mainContextBlock, to: AnyObject.self)
        self.mainContext.perform(DATAStack.performSelectorForBackgroundContext(), with: mainContextBlockObject)
    }

    /**
     Drops the database.
     */
    public func drop(completion: ((_ error: NSError?) -> Void)? = nil) {
        self.writerContext.performAndWait {
            self.writerContext.reset()

            self.mainContext.performAndWait {
                self.mainContext.reset()

                self.persistentStoreCoordinator.performAndWait {
                    for store in self.persistentStoreCoordinator.persistentStores {
                        guard let storeURL = store.url else { continue }

                        do {
                            try self.persistentStoreCoordinator.destroyPersistentStore(at: storeURL, ofType: self.storeType.type, options: store.options)
                            try! self.persistentStoreCoordinator.addPersistentStore(storeType: self.storeType, bundle: self.modelBundle, modelName: self.modelName, storeName: self.storeName, containerURL: self.containerURL)

                            DispatchQueue.main.async {
                                completion?(nil)
                            }
                        } catch let error as NSError {
                            DispatchQueue.main.async {
                                completion?(NSError(info: "Failed dropping the data stack.", previousError: error))
                            }
                        }
                    }
                }
            }
        }
    }

    /// Sends a request to all the persistent stores associated with the receiver.
    ///
    /// - Parameters:
    ///   - request: A fetch, save or delete request.
    ///   - context: The context against which request should be executed.
    /// - Returns: An array containing managed objects, managed object IDs, or dictionaries as appropriate for a fetch request; an empty array if request is a save request, or nil if an error occurred.
    /// - Throws: If an error occurs, upon return contains an NSError object that describes the problem.
    public func execute(_ request: NSPersistentStoreRequest, with context: NSManagedObjectContext) throws -> Any {
        return try self.persistentStoreCoordinator.execute(request, with: context)
    }

    // Can't be private, has to be internal in order to be used as a selector.
    func mainContextDidSave(_ notification: Notification) {
        self.saveMainThread { error in
            if let error = error {
                fatalError("Failed to save objects in main thread: \(error)")
            }
        }
    }

    // Can't be private, has to be internal in order to be used as a selector.
    func newDisposableMainContextWillSave(_ notification: Notification) {
        if let context = notification.object as? NSManagedObjectContext {
            context.reset()
        }
    }

    // Can't be private, has to be internal in order to be used as a selector.
    func backgroundContextDidSave(_ notification: Notification) throws {
        if Thread.isMainThread && TestCheck.isTesting == false {
            throw NSError(info: "Background context saved in the main thread. Use context's `performBlock`", previousError: nil)
        } else {
            let contextBlock: @convention(block) () -> Void = {
                self.mainContext.mergeChanges(fromContextDidSave: notification)
            }
            let blockObject: AnyObject = unsafeBitCast(contextBlock, to: AnyObject.self)
            self.mainContext.perform(DATAStack.performSelectorForBackgroundContext(), with: blockObject)
        }
    }

    private static func backgroundConcurrencyType() -> NSManagedObjectContextConcurrencyType {
        return TestCheck.isTesting ? .mainQueueConcurrencyType : .privateQueueConcurrencyType
    }

    private static func performSelectorForBackgroundContext() -> Selector {
        return TestCheck.isTesting ? NSSelectorFromString("performBlockAndWait:") : NSSelectorFromString("performBlock:")
    }
}

extension NSPersistentStoreCoordinator {
    func addPersistentStore(storeType: DATAStackStoreType, bundle: Bundle, modelName: String, storeName: String?, containerURL: URL) throws {
        let filePath = (storeName ?? modelName) + ".sqlite"
        switch storeType {
        case .inMemory:
            do {
                try self.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
            } catch let error as NSError {
                throw NSError(info: "There was an error creating the persistentStoreCoordinator for in memory store", previousError: error)
            }

            break
        case .sqLite:
            let storeURL = containerURL.appendingPathComponent(filePath)
            let storePath = storeURL.path

            let shouldPreloadDatabase = !FileManager.default.fileExists(atPath: storePath)
            if shouldPreloadDatabase {
                if let preloadedPath = bundle.path(forResource: modelName, ofType: "sqlite") {
                    let preloadURL = URL(fileURLWithPath: preloadedPath)

                    do {
                        try FileManager.default.copyItem(at: preloadURL, to: storeURL)
                    } catch let error as NSError {
                        throw NSError(info: "Oops, could not copy preloaded data", previousError: error)
                    }
                }
            }

            let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
            do {
                try self.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options)
            } catch {
                do {
                    try FileManager.default.removeItem(atPath: storePath)
                    do {
                        try self.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options)
                    } catch let addPersistentError as NSError {
                        throw NSError(info: "There was an error creating the persistentStoreCoordinator", previousError: addPersistentError)
                    }
                } catch let removingError as NSError {
                    throw NSError(info: "There was an error removing the persistentStoreCoordinator", previousError: removingError)
                }
            }

            let shouldExcludeSQLiteFromBackup = storeType == .sqLite && TestCheck.isTesting == false
            if shouldExcludeSQLiteFromBackup {
                do {
                    try (storeURL as NSURL).setResourceValue(true, forKey: .isExcludedFromBackupKey)
                } catch let excludingError as NSError {
                    throw NSError(info: "Excluding SQLite file from backup caused an error", previousError: excludingError)
                }
            }

            break
        }
    }
}

extension NSManagedObjectModel {
    convenience init(bundle: Bundle, name: String) {
        if let momdModelURL = bundle.url(forResource: name, withExtension: "momd") {
            self.init(contentsOf: momdModelURL)!
        } else if let momModelURL = bundle.url(forResource: name, withExtension: "mom") {
            self.init(contentsOf: momModelURL)!
        } else {
            self.init()
        }
    }
}

extension NSError {
    convenience init(info: String, previousError: NSError?) {
        if let previousError = previousError {
            var userInfo = previousError.userInfo
            if let _ = userInfo[NSLocalizedFailureReasonErrorKey] {
                userInfo["Additional reason"] = info
            } else {
                userInfo[NSLocalizedFailureReasonErrorKey] = info
            }

            self.init(domain: previousError.domain, code: previousError.code, userInfo: userInfo)
        } else {
            var userInfo = [String: String]()
            userInfo[NSLocalizedDescriptionKey] = info
            self.init(domain: "com.SyncDB.DATAStack", code: 9999, userInfo: userInfo)
        }
    }
}

extension URL {
    fileprivate static func directoryURL() -> URL {
        #if os(tvOS)
            return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).last!
        #else
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
        #endif
    }
}
