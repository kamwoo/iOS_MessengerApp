//
//  ViewController.swift
//  iOS_MessengerApp
//
//  Created by wooyeong kam on 2021/06/13.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

class ConversationsViewController: UIViewController {
    
    // MARK: -views
    // 로딩 뷰어 선언
    private let spinner = JGProgressHUD(style: .dark)
    
    // 테이블 뷰 생성, 대화가 없다면 보이지 않음
    private let tableView : UITableView = {
       let table = UITableView()
        table.isHidden = true
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
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
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true, completion: nil)
    }
    
    
    private func fetchConversations() {
        tableView.isHidden = false
    }


}

// 테이블 뷰 세팅
extension ConversationsViewController : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = "hello world"
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    // 각 셀이 선택되면 해당하는 NewConversationView으로 전환
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = ChatViewController()
        vc.title = "Kam woo"
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
}

