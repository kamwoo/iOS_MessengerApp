//
//  NewConversationViewController.swift
//  iOS_MessengerApp
//
//  Created by wooyeong kam on 2021/06/13.
//

import UIKit
import JGProgressHUD

// 새로운 대화만들기 뷰

class NewConversationViewController: UIViewController {
    // 
    public var completion : ((SearchResult) -> Void)?
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private var users = [[String: String]]()
    // 테이블에 표시된 어레이
    private var results = [SearchResult]()
    private var hasFetched = false
    
    // 상단 대화상대 찾기 검색바 생성
    private let searchBar : UISearchBar = {
       let searchBar = UISearchBar()
        searchBar.placeholder = "대화할 상대를 선택해주세요..."
        return searchBar
    }()
    
    // 테이블 뷰, 사람이 없다면 보이지 않는다.
    private let tableView : UITableView = {
       let table = UITableView()
        table.isHidden = true
        table.register(NewConversationCell.self, forCellReuseIdentifier: NewConversationCell.identifier)
        return table
    }()
    
    // 사람이 없을 때 보여질 뷰
    private let noResultsLabel: UILabel = {
       let label = UILabel()
        label.isHidden = true
        label.text = "검색 결과가 없습니다."
        label.textAlignment = .center
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 21, weight: .medium)
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(noResultsLabel)
        view.addSubview(tableView)
        
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        // 네비게이션 상단을 검색바 아이템으로 설정
        navigationController?.navigationBar.topItem?.titleView = searchBar
        // 검색 취소 버튼 생성
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancle",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(dismissSelf))
        // 검색창으로 넘어오고, 바로 검색바에 포커싱한다.
        searchBar.becomeFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noResultsLabel.frame = CGRect(x: view.width/4, y: (view.height-200)/2, width: view.width/2, height: 100)
    }
    
    // 창닫기
    @objc private func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }

}

extension NewConversationViewController : UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = results[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: NewConversationCell.identifier, for: indexPath) as! NewConversationCell
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // start conversation
        let targetUserData = results[indexPath.row]
        // 유저 선택창을 닫은 뒤 선택된 상대로 채팅뷰로 넘김
        dismiss(animated: true){ [weak self] in
            self?.completion?(targetUserData)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
}


extension NewConversationViewController : UISearchBarDelegate {
    // 검색 버튼이 클릭되고 액션
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        print("searchBarSearchButtonClicked")
        
        searchBar.resignFirstResponder()
        
        // 새로 검색할 때 마다 삭제
        results.removeAll()
        
        spinner.show(in: view)
        
        self.searchUsers(query: text)
        
    }
    
    // request가 되었다면 필터, 아니라면 유저정보 request
    func searchUsers(query: String){
        if hasFetched {
            filterUsers(with: query)
        }else{
            DatabaseManager.shared.getAllUsers(completion: { [weak self] result in
                guard let self = self else {return}
                switch result{
                case .success(let userCollection):
                    self.hasFetched = true
                    self.users = userCollection
                    self.filterUsers(with: query)
                case .failure(let error):
                    print("NewConversation - getAllUsers error \(error) ")
                }
            })
        }
    }
    
    // 전송받은 유저이름 리스트에서 유저 이름 필터
    func filterUsers(with term : String){
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String, hasFetched else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        
        self.spinner.dismiss()
        
        // 받아온 유저들의 정보에서 현재 유저와 이메일이 같지않은 이메일, 이름들을 search Result에 담음
        let results : [SearchResult] = self.users.filter({
            guard let email = $0["email"], email != safeEmail else{
                return false
            }
            
            guard let name = $0["name"] else { return false}
            return name.hasPrefix(term.lowercased())
        }).compactMap({
            guard let email = $0["email"], let name = $0["name"] else {return nil}
            
            return SearchResult(name: name, email: email)
        })
        
        self.results = results
        
        updateUI()
       
    }
    
    // 검색 결과의 유무에 따라 검색결과 창 결정
    func updateUI(){
        if results.isEmpty{
            print("no reault")
            self.noResultsLabel.isHidden = false
            self.tableView.isHidden = true
        }else{
            self.noResultsLabel.isHidden = true
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }
    }
}


struct SearchResult {
    let name : String
    let email : String
}
