import CoreData
import Sync
import Networking
import Alamofire

class Fetcher {
    private let persistentContainer: NSPersistentContainer
    private lazy var networking: Networking = {
        Networking(baseURL: "https://jsonplaceholder.typicode.com")
    }()

    init() {
        let modelName = "DataModel"
        self.persistentContainer = NSPersistentContainer(name: modelName)
        let containerURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
        let storeURL = containerURL.appendingPathComponent("\(modelName).sqlite")
        try! self.persistentContainer.persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
    }

    func fetchLocalUsers() -> [User] {
        let request: NSFetchRequest<User> = User.fetchRequest()

        return try! self.persistentContainer.viewContext.fetch(request)
    }

    func networkingUsers(completion: @escaping (_ result: VoidResult) -> ()) {
        self.networking.get("/users") { result in
            switch result {
            case .success(let response):
                let usersJSON = response.arrayBody
                self.persistentContainer.sync(usersJSON, inEntityNamed: User.entity().name!) { error in
                    completion(.success)
                }
            case .failure(let response):
                completion(.failure(response.error))
            }
        }
    }

    func alamofireUsers(completion: @escaping (_ result: VoidResult) -> ()) {
        Alamofire.request("https://jsonplaceholder.typicode.com/users").responseJSON { response in
            if let jsonObject = response.result.value, let usersJSON = jsonObject as? [[String: Any]] {
                self.persistentContainer.sync(usersJSON, inEntityNamed: User.entity().name!) { error in
                    completion(.success)
                }
            } else if let error = response.error {
                completion(.failure(error as NSError))
            } else {
                fatalError("No error, no failure")
            }
        }
    }
}

enum VoidResult {
    case success
    case failure(NSError)
}
