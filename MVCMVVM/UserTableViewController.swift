//
//  ViewController.swift
//  MVCMVVM
//
//  Created by Satyaa on 05/04/21.
//

import UIKit

class UserTableViewController: UITableViewController {
    var users: [User] = []{
        didSet{
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchusers()
    }
    private func fetchusers(){
        APIManager.shared.fetchUsers { (result) in
            switch result{
            case .success(let users):
                DispatchQueue.main.async {
                    self.users = users
                }
            case .failure(let error):
                print(error.localizedDescription)
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

class APIManager{
    static let shared: APIManager = {
        let instance = APIManager()
        return instance
    }()
    func fetchUsers(completion: @escaping (Result<[User], Error>) -> Void){
        let urlString = "https://jsonplaceholder.typicode.com/users"
        let url = URL(string: urlString)!
        URLSession.shared.dataTask(with: url){ (data, response, error) in
            if let error = error{
                completion(.failure(error))
            }
            guard let data = data else{
                fatalError("Data cannot be Found")
            }
            do{
                let users = try JSONDecoder().decode([User].self, from: data)
                completion(.success(users))
            }catch{
                completion(.failure(error))
            }
        }.resume()
    }
}

struct User: Decodable{
    let id: Int
    let name: String
    let email: String
}
