//
//  ViewController.swift
//  iOS_MessengerApp
//
//  Created by wooyeong kam on 2021/06/13.
//

import UIKit
import FirebaseAuth
import JGProgressHUD



final class ConversationsViewController: UIViewController {
    
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
    
    private var loginObserver : NSObjectProtocol?
    
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
        startListeningForConversations()
        
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification,
                                                               object: nil,
                                                               queue: .main,
                                                               using: { [weak self] _ in
                                                                guard let self = self else {return}
                                                                self.startListeningForConversations()
                                                               })
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
        noConversationsLabel.frame = CGRect(x: 10, y: (view.height-100)/2, width: view.width-20, height: 100)
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
            
            let currentConversations = self.conversations
            
            if let targetConversation = currentConversations.first(where: {
                $0.otherUserEmail == DatabaseManager.safeEmail(emailAddress: result.email)
            }){
                let vc = ChatViewController(with: targetConversation.otherUserEmail, id: targetConversation.id)
                vc.isNewConversation = false
                vc.title = targetConversation.name
                vc.navigationItem.largeTitleDisplayMode = .never
                self.navigationController?.pushViewController(vc, animated: true)
            }else{
                self.createNewConversation(result: result)
            }
            
        }
        
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true, completion: nil)
    }
    
    // newConversation view가 완료되고 난 뒤 채팅 뷰로 전환
    private func createNewConversation(result : SearchResult){
        let name = result.name
        let email = DatabaseManager.safeEmail(emailAddress: result.email)
        
        // 대화방이 한쪽이 지우더라도 다른 한쪽이 나가지 않았는지 확인하고, 있으면 그 대화방을 재사용하고, 없으면 새로 생성
        DatabaseManager.shared.conversationExists(with: email, completion: {[weak self] result in
            guard let self = self else {return}
            
            switch result {
            case .success(let conversationId):
                let vc = ChatViewController(with: email, id: conversationId)
                vc.isNewConversation = false
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                self.navigationController?.pushViewController(vc, animated: true)
                
            case .failure(_):
                let vc = ChatViewController(with: email, id: nil)
                vc.isNewConversation = true
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                self.navigationController?.pushViewController(vc, animated: true)
            }
        })
        
    }
    
    
    // 현재 유저의 데이터베이스에 저장된 대화들을 리턴받아 conversatoins에 저장
    private func startListeningForConversations() {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        // 현재 유저의 저장된 대화방 리스트 데이터 쿼리
        DatabaseManager.shared.getAllConversation(for: safeEmail, completion: {[weak self] result in
            switch result {
            case .success(let conversations):
                guard !conversations.isEmpty else {
                    self?.tableView.isHidden = true
                    self?.noConversationsLabel.isHidden = false
                    return
                }
                self?.tableView.isHidden = false
                self?.noConversationsLabel.isHidden = true
                self?.conversations = conversations
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
                
            case .failure(let error):
                self?.tableView.isHidden = true
                self?.noConversationsLabel.isHidden = false
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
        
        openConversation(model)
    }
    
    
    func openConversation(_ model: Conversation) {
        // 선택된 셀의 대화 세부정보중에 대화 상대 이메일과 대화방 아이디를 넘김
        let vc = ChatViewController(with: model.otherUserEmail, id: model.id)
        vc.title = model.name // 상대방 이름
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let conversationId = conversations[indexPath.row].id
            tableView.beginUpdates()
            self.conversations.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .left)
            
            DatabaseManager.shared.deleteConversation(conversationId: conversationId , completion: { success in
                if !success {
                    print("failed to remove conversation")
                }
                
            })
            

            tableView.endUpdates()
        }
    }
}



