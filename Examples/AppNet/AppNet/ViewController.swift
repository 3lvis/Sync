import UIKit
import DATAStack

class ViewController: UITableViewController {
    struct Constant {
      static let SYNCCellIdentifier = "CellID"
      static let SYNCReloadTableNotification = "SYNCReloadTableNotification"
  }

  let dataStack: DATAStack
  lazy var networking: Networking = { [unowned self] in Networking(dataStack: self.dataStack) }()
  var items = [Data]()

  // MARK: Initializers

  required init(dataStack: DATAStack) {
    self.dataStack = dataStack
    super.init(nibName: nil, bundle: nil);
  }

  required init!(coder aDecoder: NSCoder!) {
      fatalError("init(coder:) has not been implemented")
  }

  // MARK: View Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()

    title = "AppNet"
    tableView.registerClass(UITableViewCell.classForCoder(), forCellReuseIdentifier: Constant.SYNCCellIdentifier)

    fetchCurrentObjects()
    fetchNewData()
  }

  // MARK: Networking methods

  func fetchNewData() {
    networking.fetchNewContent { [unowned self] in
      self.fetchCurrentObjects()
    }
  }

  // MARK: Model methods

  func fetchCurrentObjects() {
    let request = NSFetchRequest(entityName: "Data")
    request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
    items = dataStack.mainContext.executeFetchRequest(request, error: nil) as! [Data]

    tableView.reloadData()
  }
}

extension ViewController: UITableViewDataSource {

  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return items.count
  }

  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    var cell = self.tableView.dequeueReusableCellWithIdentifier(Constant.SYNCCellIdentifier) as! UITableViewCell
    let data = self.items[indexPath.row]

    cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: Constant.SYNCCellIdentifier)

    cell.textLabel?.text = data.text
    cell.textLabel?.numberOfLines = 1
    cell.detailTextLabel?.text = data.user.username

    return cell
  }
}
