import UIKit

class Observable<T> {
    var value: T? {
        didSet {
            listeners.forEach { $0(value) }
        }
    }
    
    init(_ value: T?) {
        self.value = value
    }
    
    private var listeners: [((T?) -> Void)] = []
        
    func bind(_ listener: @escaping ((T?) -> Void)) {
        listener(value)
        self.listeners.append(listener)
    }
}

//ViewModel
struct UserListViewModel {
    var users: Observable<[UserTableViewCellViewModel]> = Observable([])
}

struct User: Codable {
    let name: String
}

struct UserTableViewCellViewModel {
    let name: String
}

final class ViewController: UIViewController, UITableViewDataSource {
    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.dataSource = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return table
    }()
    
    private let viewModel = UserListViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        tableView.frame = view.bounds
        
        viewModel.users.bind({ [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        })
        
        fetchData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.users.value?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = viewModel.users.value?[indexPath.row].name
        return cell
    }
    

    func fetchData() {
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/users") else { return }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] (data, _, _) in
            guard let self = self else { return }
            guard let data = data else { return }
            
            do {
                let userModels = try JSONDecoder().decode([User].self, from: data)
                self.viewModel.users.value = userModels.compactMap({ UserTableViewCellViewModel(name: $0.name) })
            }
            catch {
                
            }
        }
        
        task.resume()
    }
}


