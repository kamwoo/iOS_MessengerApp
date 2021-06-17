//
//  ProfileViewController.swift
//  iOS_MessengerApp
//
//  Created by wooyeong kam on 2021/06/13.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit

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
        StorageManager.shared.downloadUrl(for: path, completion: {[weak self] result in
            guard let self = self else {return}
            
            switch result {
            case .success(let url):
                self.downloadImage(imageView: imageView, url: url)
            case .failure(let error):
                print("ProfileViewController - downloadUrl error \(error)")
            }
        })
        
        return headerView
    }
    
    // 저장소로부터 받은 유저의 프로필 이미지 주소로 이미지 request
    func downloadImage(imageView : UIImageView, url : URL){
        URLSession.shared.dataTask(with: url){ (data, _, error) in
            guard let data = data , error == nil else{
                return
            }
            // 리턴된 이미지를 imageView에 지정
            DispatchQueue.main.async {
                let image = UIImage(data: data)
                imageView.image = image
            }
        }.resume()
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
        
        present(alert, animated: true, completion: nil)
    }
}
