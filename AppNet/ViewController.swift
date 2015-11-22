import UIKit
import DATAStack
import CoreData

class ViewController: UITableViewController {
    let CellIdentifier = "CellID"

    let dataStack: DATAStack
    lazy var networking: Networking = { [unowned self] in Networking(dataStack: self.dataStack) }()
    var items = [Data]()

    // MARK: Initializers

    required init(dataStack: DATAStack) {
        self.dataStack = dataStack
        super.init(nibName: nil, bundle: nil);
    }

    required init!(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "AppNet"
        tableView.registerClass(UITableViewCell.classForCoder(), forCellReuseIdentifier: CellIdentifier)

        setUpRefreshControl()
        fetchCurrentObjects()
        fetchNewData()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "changeNotification:", name: NSManagedObjectContextObjectsDidChangeNotification, object: self.dataStack.mainContext)
    }

    func changeNotification(notification: NSNotification) {
        let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey]
        let deletedObjects = notification.userInfo?[NSDeletedObjectsKey]
        let insertedObjects = notification.userInfo?[NSInsertedObjectsKey]

        print("updatedObjects: \(updatedObjects)")
        print("deletedObjects: \(deletedObjects)")
        print("insertedObjects: \(insertedObjects)")
    }

    func setUpRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: "fetchNewData", forControlEvents: .ValueChanged)
    }

    // MARK: Networking methods

    func fetchNewData() {
        networking.fetchItems { _ in
            self.fetchCurrentObjects()

            self.refreshControl?.endRefreshing()
        }
    }

    // MARK: Model methods

    func fetchCurrentObjects() {
        let request = NSFetchRequest(entityName: "Data")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        items = (try! dataStack.mainContext.executeFetchRequest(request)) as! [Data]

        tableView.reloadData()
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier(CellIdentifier)
        let data = self.items[indexPath.row]
        cell?.textLabel?.text = data.text

        // Workaround: The proper value of `numberOfLines` should be 0
        // but there's a weird bug that causes UITableView to go crazy
        cell?.textLabel?.numberOfLines = 1
        cell?.detailTextLabel?.text = data.user.username
        
        return cell!
    }
}
