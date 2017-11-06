import UIKit
import Sync

class ItemsController: UITableViewController {
    var fetcher: Fetcher

    var users = [User]()

    init(style: UITableViewStyle = .plain, fetcher: Fetcher) {
        self.fetcher = fetcher

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.dataSource = self
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: String(describing: UITableViewCell.self))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Refresh", style: .done, target: self, action: #selector(refresh))

        self.users = self.fetcher.fetchLocalUsers()
        self.refresh()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UITableViewCell.self), for: indexPath)
        let user = self.users[indexPath.row]
        cell.textLabel?.text = user.name

        return cell
    }

    @objc func refresh() {
        self.fetcher.networkingUsers { result in
            switch result {
            case .success:
                self.users = self.fetcher.fetchLocalUsers()
                self.tableView.reloadData()
            case .failure(let error):
                print(error)
            }
        }
    }
}
