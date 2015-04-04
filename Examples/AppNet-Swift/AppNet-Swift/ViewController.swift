import UIKit

class ViewController: UITableViewController {

    var dataStack: DATAStack!

    // MARK: Initializers

    required init(dataStack: DATAStack)
    {
        super.init(nibName: nil, bundle: nil);
        self.dataStack = dataStack
    }

    required init(coder aDecoder: NSCoder) {
        super.init(nibName: nil, bundle: nil);
    }

    // MARK: Viewcycle

    override func viewDidLoad()
    {
        super.viewDidLoad()
    }
}

