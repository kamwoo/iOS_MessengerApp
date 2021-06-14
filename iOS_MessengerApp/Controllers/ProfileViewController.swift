//
//  ProfileViewController.swift
//  iOS_MessengerApp
//
//  Created by wooyeong kam on 2021/06/13.
//

import UIKit
import FirebaseAuth

// 프로필 화면 

class ProfileViewController: UIViewController {
    
    @IBOutlet var tableView : UITableView!
    
    // 테이블 뷰 셀 데이터 어레이
    let data = ["Log Out"]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self

    }
    

}

extension ProfileViewController : UITableViewDelegate,UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = data[indexPath.row]
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = .red
        return cell
    }
    
    // 각 셀이 선택되었을 때 실행
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // actionSheet설정
        let alert = UIAlertController(title: "로그아웃",
                                      message: "로그아웃 하시겠습니까?",
                                      preferredStyle: .alert)
        
        // actionSheet에 확인 버튼 추가
        alert.addAction(UIAlertAction(title: "확인",
                                      style: .destructive,
                                      handler: { [weak self] _ in
                                        guard let self = self else {return}
                                        // Firebase auth를 이용하여 로그아웃
                                        do {
                                            try FirebaseAuth.Auth.auth().signOut()
                                            // 로그인 화면으로 전환
                                            let vc = LoginViewController()
                                            let nav = UINavigationController(rootViewController: vc)
                                            // 뷰가 어떻게 보여질지 설정
                                            nav.modalPresentationStyle = .fullScreen
                                            self.present(nav, animated: true, completion: nil)
                                            
                                        }catch {
                                            print("Fail to Log out")
                                        }
                                      }))
        
        // action Sheet에 취소 버튼 추가
        alert.addAction(UIAlertAction(title: "취소",
                                      style: .cancel,
                                      handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
}
