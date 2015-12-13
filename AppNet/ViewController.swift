import UIKit
import DATAStack
import CoreData

class ViewController: UITableViewController {
    let CellIdentifier = "CellID"

    unowned var dataStack: DATAStack
    lazy var networking: Networking = Networking(dataStack: self.dataStack)
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
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: CellIdentifier)

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: "fetchNewData", forControlEvents: .ValueChanged)

        fetchCurrentObjects()
        fetchNewData()
    }

    func fetchNewData() {
        networking.fetchItems { _ in
            self.fetchCurrentObjects()

            self.refreshControl?.endRefreshing()
        }
    }

    func fetchCurrentObjects() {
        let request = NSFetchRequest(entityName: "Data")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        items = (try! dataStack.mainContext.executeFetchRequest(request)) as! [Data]
        tableView.reloadData()
    }
}

// MARK: UITableViewDataSource

extension ViewController {
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier)
        let data = items[indexPath.row]
        cell?.textLabel?.text = data.text

        // Workaround: The proper value of `numberOfLines` should be 0
        // but there's a weird bug that causes UITableView to go crazy
        cell?.textLabel?.numberOfLines = 1
        cell?.detailTextLabel?.text = data.user.username

        return cell!
    }
}
