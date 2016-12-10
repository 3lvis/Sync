import UIKit
import DATAStack
import CoreData

class ViewController: UITableViewController {
    unowned var dataStack: DATAStack
    var items = [NSManagedObject]()

    required init(dataStack: DATAStack) {
        self.dataStack = dataStack
        super.init(nibName: nil, bundle: nil)
    }

    required init!(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Demo"
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: String(describing: UITableViewCell.self))

        self.fetchCurrentObjects()
        self.fetchNewData()
    }

    func fetchNewData() {
        let fileName = "sample.json"
        let url = URL(string: fileName)!
        let filePath = Bundle.main.path(forResource: url.deletingPathExtension().absoluteString, ofType: url.pathExtension)!
        let data = try! Data(contentsOf: URL(fileURLWithPath: filePath))
        let json = try! JSONSerialization.jsonObject(with: data, options: []) as! [[String: Any]]

        Sync.changes(json, inEntityNamed: "User", dataStack: self.dataStack) { error in
            self.fetchCurrentObjects()
        }
    }

    func fetchCurrentObjects() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "User")
        request.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        self.items = (try! dataStack.mainContext.fetch(request)) as! [NSManagedObject]
        self.tableView.reloadData()
    }
}

extension ViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UITableViewCell.self))
        let data = self.items[indexPath.row]
        cell?.textLabel?.text = data.value(forKey: "id") as? String

        return cell!
    }
}
