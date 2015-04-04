import UIKit

class ViewController: UITableViewController, UITableViewDelegate, UITableViewDataSource {
    let SYNCCellIdentifier = "CellID"
    let SYNCReloadTableNotification = "SYNCReloadTableNotification"

    let dataStack: DATAStack!
    var arrayWithData: [NSManagedObject] = []

    // MARK: Initializers

    required init(dataStack: DATAStack) {
        super.init(nibName: nil, bundle: nil);
        self.dataStack = dataStack
    }

    required init(coder aDecoder: NSCoder) {
        super.init(nibName: nil, bundle: nil);
    }

    // MARK: View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.arrayWithData = Array()

        self.title = "AppNet"

        self.tableView.registerClass(UITableViewCell.classForCoder(), forCellReuseIdentifier: SYNCCellIdentifier)
        self.tableView.allowsSelection = false

        fetchCurrentObjects()

        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "finishedFetchingPosts", name: SYNCReloadTableNotification, object: nil)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        fetchNewData()
    }

    // MARK: TableView methods

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrayWithData.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell! = self.tableView.dequeueReusableCellWithIdentifier(SYNCCellIdentifier) as UITableViewCell
        let data: Data = self.arrayWithData[indexPath.row] as Data

        cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: SYNCCellIdentifier)

        cell.textLabel!.text = data.text
        cell.textLabel!.numberOfLines = 1000
        cell.detailTextLabel!.text = data.user.username

        return cell
    }

    // MARK: Notification

    func finishedFetchingPosts() {
        fetchCurrentObjects()
    }

    // MARK: Networking methods

    func fetchNewData() {
        let networking = Networking(dataStack: self.dataStack)
        networking.fetchNewContent()
    }

    // MARK: Model methods

    func fetchCurrentObjects() {
        let request = NSFetchRequest(entityName: "Data")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        self.arrayWithData = self.dataStack.mainContext.executeFetchRequest(request, error: nil) as Array
        
        self.tableView.reloadData()
    }

}

