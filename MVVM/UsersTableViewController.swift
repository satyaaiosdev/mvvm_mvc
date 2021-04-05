//
//  ViewController.swift
//  MVVM
//
//  Created by Satyaa on 05/04/21.
//

import UIKit
import Combine

class UsersViewModel{
    //Dependency Injection
    private let apiManager: ApiManager!
    private let endPoint: EndPoint!
    var usersSubject = PassthroughSubject<[User], Error>()
    init(apiManager: ApiManager, endPoint: EndPoint){
        self.apiManager = apiManager
        self.endPoint = endPoint
    }
    func fetchUser(){
        let url = URL(string: endPoint.urlString)!
        apiManager.fetchItems(url: url) { [weak self] (result: Result<[User], Error>) in
            switch result{
            case .success(let items):
                self?.usersSubject.send(items)
            case .failure(let error):
                self?.usersSubject.send(completion: .failure(error))
            }
        }
    }
}


class UsersTableViewController: UITableViewController {
    var viewModel: UsersViewModel!
    private let apimanager =  ApiManager()
    var users: [User] = []
    private var subscriber: AnyCancellable?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupViewModel()
        self.fetchUsers()
        self.observeViewModel()
    }
    func setupViewModel(){
        viewModel = UsersViewModel(apiManager: apimanager, endPoint: .usersFetch)
    }
    
    func fetchUsers(){
        viewModel.fetchUser()
    }
    func observeViewModel(){
        subscriber = viewModel.usersSubject.sink { (resultCompletion) in
            switch resultCompletion{
            case .failure(let error):
                print(error.localizedDescription)
            default:
                break
            }
        } receiveValue: { (users) in
            DispatchQueue.main.async {
                self.users = users
                self.tableView.reloadData()
            }
           
            
        }

    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        users.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = users[indexPath.row].name
        cell.detailTextLabel?.text = users[indexPath.row].email
        
        return cell
    }

}


struct User: Decodable{
    let id: Int
    let name: String
    let email: String
}

class ApiManager{
    private var subscribers = Set<AnyCancellable>()
    func fetchItems<T: Decodable>(url: URL, completion: @escaping (Result<[T], Error>)-> Void){
        URLSession.shared.dataTaskPublisher(for: url)
            .map{ $0.data}
            .decode(type: [T].self, decoder: JSONDecoder())
            .sink { (resultCompletion) in
                switch resultCompletion{
                case .failure(let error):
                    completion(.failure(error))
                case .finished: break
                }
            } receiveValue: { (resultArray) in
                completion(.success(resultArray))
            }.store(in: &subscribers)

    }
}

enum EndPoint{
    case usersFetch
    case commentsFetch
    var  urlString: String{
        switch self {
        case .usersFetch:
            return "https://jsonplaceholder.typicode.com/users"
        case .commentsFetch:
            return "https://jsonplaceholder.typicode.com/users"
        }
    }
}
