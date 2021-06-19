//
//  ViewController.swift
//  iOS_MessengerApp
//
//  Created by wooyeong kam on 2021/06/13.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

// 대화 세부 정보
struct Conversation {
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
}

// 가장 최근 메세지
struct LatestMessage {
    let date: String
    let text: String
    let isRead: Bool
}

class ConversationsViewController: UIViewController {
    
    // MARK: -views
    // 로딩 뷰어 선언
    private let spinner = JGProgressHUD(style: .dark)
    
    private var conversations = [Conversation]()
    
    // 테이블 뷰 생성, 대화가 없다면 보이지 않음
    private let tableView : UITableView = {
       let table = UITableView()
        table.isHidden = true
        table.register(ConversationTableViewCell.self, forCellReuseIdentifier: ConversationTableViewCell.identifier)
        return table
    }()
    
    // 대화가 없을 때 보여질 뷰 생성
    private let noConversationsLabel : UILabel = {
       let label = UILabel()
        label.text = "No Conversations"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = UIFont.systemFont(ofSize: 21, weight: .medium)
        label.isHidden = true
        return label
    }()
    
    
    // MARK: - LiftCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // 새로운 대화창 생성 버튼 설정
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose,
                                                            target: self,
                                                            action: #selector(didtapComposeButton))
        
        view.addSubview(tableView)
        view.addSubview(noConversationsLabel)
        setupTableView()
        fetchConversations()
        startListeningForConversations()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
//         앱 전체에서 전역적으로 적용
//        let isLoggedIn = UserDefaults.standard.bool(forKey: "logged_in")
        
        validateAuth()
        
    }
    
    // 테이블뷰 delegate 설정
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    // 레이아웃이 설정되고 추가로 테이블뷰 크기를 뷰의 경계로 지정
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    // 현재 로그인 상태인지 체크하고, 로그아웃 상태라면 로그인 페이지로 전환
    private func validateAuth() {
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true, completion: nil)
        }
    }
    
    // 새로운 대화창 생성 버튼 클릭시 NewConversationViewController로 전환
    @objc private func didtapComposeButton() {
        let vc = NewConversationViewController()
        // newConversation view가 완료되고 난 후 로직을 설정
        vc.completion = { [weak self] result in
            guard let self = self else {return}
            print("\(result)")
            self.createNewConversation(result: result)
        }
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true, completion: nil)
    }
    
    // newConversation view가 완료되고 난 뒤 채팅 뷰로 전환
    private func createNewConversation(result : [String : String]){
        guard let name = result["name"], let email = result["email"] else {
            return
        }
        let vc = ChatViewController(with: email, id: nil)
        vc.isNewConversation = true
        vc.title = name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    private func fetchConversations() {
        tableView.isHidden = false
    }
    
    // 현재 유저의 데이터베이스에 저장된 대화들을 리턴받아 conversatoins에 저장
    private func startListeningForConversations() {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        DatabaseManager.shared.getAllConversation(for: safeEmail, completion: {[weak self] result in
            switch result {
            case .success(let conversations):
                guard !conversations.isEmpty else {
                    return
                }
                self?.conversations = conversations
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
                
            case .failure(let error):
                print("failed to get convo : \(error)")
            }
        })
    }


}

// 테이블 뷰 세팅
extension ConversationsViewController : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 각 대화 세부 정보로 셀 생성
        let model = conversations[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier,
                                                 for: indexPath) as! ConversationTableViewCell
        // 각 대화방의 정보로 각 셀을 설정
        cell.configure(with: model)
        return cell
    }
    
    // 각 셀이 선택되면 해당하는 NewConversationView으로 전환
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = conversations[indexPath.row]
        
        // 선택된 셀의 대화 세부정보중에 대화 상대 이메일과 대화방 아이디를 넘김
        let vc = ChatViewController(with: model.otherUserEmail, id: model.id)
        vc.title = model.name // 상대방 이름
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
}

