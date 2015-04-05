import UIKit

class ViewController: UITableViewController, UITableViewDelegate, UITableViewDataSource {
  let SYNCCellIdentifier = "CellID"
  let SYNCReloadTableNotification = "SYNCReloadTableNotification"

  let dataStack: DATAStack!
  var networking: Networking!
  var items = [Data]()

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

    self.title = "AppNet"
    self.tableView.registerClass(UITableViewCell.classForCoder(), forCellReuseIdentifier: SYNCCellIdentifier)
    self.tableView.allowsSelection = false

    self.items = Array()
    fetchCurrentObjects()
  }

  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(true)

    fetchNewData()
  }

  // MARK: TableView methods

  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return items.count
  }

  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    var cell = self.tableView.dequeueReusableCellWithIdentifier(SYNCCellIdentifier) as UITableViewCell
    let data = self.items[indexPath.row]

    cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: SYNCCellIdentifier)

    cell.textLabel?.text = data.text
    cell.textLabel?.numberOfLines = 1000
    cell.detailTextLabel?.text = data.user.username

    return cell
  }

  // MARK: Networking methods

  func fetchNewData() {
    self.networking = Networking(dataStack: self.dataStack)
    self.networking.fetchNewContent { () -> Void in
      self.fetchCurrentObjects()
    }
  }

  // MARK: Model methods

  func fetchCurrentObjects() {
    let request = NSFetchRequest(entityName: "Data")
    request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
    self.items = self.dataStack.mainContext.executeFetchRequest(request, error: nil) as Array

    tableView.reloadData()
  }
}
