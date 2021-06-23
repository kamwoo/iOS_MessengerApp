//
//  ProfileViewController.swift
//  iOS_MessengerApp
//
//  Created by wooyeong kam on 2021/06/13.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import SDWebImage



final class ProfileViewController: UIViewController {
    
    @IBOutlet var tableView : UITableView!
    
    // 테이블 뷰 셀 데이터 어레이
    var data = [profileViewModel]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: ProfileTableViewCell.idenfifier)
        
        data.append(profileViewModel(viewModelType: .info,
                                     title: "Name : \(UserDefaults.standard.value(forKey: "name") ?? "No name")",
                                     handler: nil))
        
        data.append(profileViewModel(viewModelType: .info,
                                     title: "Name : \(UserDefaults.standard.value(forKey: "email") ?? "No email")",
                                     handler: nil))
        
        data.append(profileViewModel(viewModelType: .logout, title: "Log out", handler: {[weak self] in
            // actionSheet설정
            let alert = UIAlertController(title: "로그아웃",
                                          message: "로그아웃 하시겠습니까?",
                                          preferredStyle: .alert)
            
            // actionSheet에 확인 버튼 추가
            alert.addAction(UIAlertAction(title: "확인",
                                          style: .destructive,
                                          handler: { [weak self] _ in
                                            guard let self = self else {return}
                                            
                                            UserDefaults.standard.setValue(nil, forKey: "email")
                                            UserDefaults.standard.setValue(nil, forKey: "name")
                                            
                                            // 페이스북 로그아웃
                                            FBSDKLoginKit.LoginManager().logOut()
                                            
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
            
            self?.present(alert, animated: true, completion: nil)
        }))
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = createTableHeader()
    }
    
    // 프로필 뷰 상단 이미지 테이블
    func createTableHeader() -> UIView? {
        // 로그인시 지정한 유저 전역 이메일
        guard let email = UserDefaults.standard.value(forKey: "email") else {
            return nil
        }
        // safe이메일로 변경후 저장소 경로 설정
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email as! String)
        let fileName = safeEmail + "_profile_picture.png"
        let path = "images/" + fileName
        
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.width, height: 300))
        headerView.backgroundColor = .link
        
        let imageView = UIImageView(frame: CGRect(x: (view.width-150)/2, y: 75, width: 150, height: 150))
        imageView.contentMode = .scaleAspectFill
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 3
        imageView.backgroundColor = .white
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = imageView.width / 2
        headerView.addSubview(imageView)
        
        // 지정된 경로에서 받은 이미지 주소를 이미지뷰와 연결
        StorageManager.shared.downloadUrl(for: path, completion: {result in
            switch result {
            case .success(let url):
                imageView.sd_setImage(with: url, completed: nil)
                
            case .failure(let error):
                print("ProfileViewController - downloadUrl error \(error)")
            }
        })
        return headerView
    }
    
}

extension ProfileViewController : UITableViewDelegate,UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = data[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileTableViewCell.idenfifier,
                                                 for: indexPath) as! ProfileTableViewCell
        cell.setUp(with: viewModel)
        return cell
    }
    
    // 각 셀이 선택되었을 때 실행
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        data[indexPath.row].handler?()
        
    }
}

class ProfileTableViewCell : UITableViewCell{
    
    static let idenfifier = "ProfileTableViewCell"
    
    public func setUp(with viewModel: profileViewModel) {
        textLabel?.text = viewModel.title
        switch viewModel.viewModelType {
        case .info:
            textLabel?.textAlignment = .left
            selectionStyle = .none
        case .logout:
            textLabel?.textColor = .red
            textLabel?.textAlignment = .center
        }
    }
}
