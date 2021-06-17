//
//  LoginViewController.swift
//  iOS_MessengerApp
//
//  Created by wooyeong kam on 2021/06/13.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import JGProgressHUD

class LoginViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private let scrollView : UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    // 로고이미지
    private let imageView : UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "logo")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    // 이메일 입력 필드
    private let emailField : UITextField = {
        let textfield = UITextField()
        textfield.autocapitalizationType = .none
        textfield.autocorrectionType = .no
        textfield.returnKeyType = .continue
        textfield.layer.cornerRadius = 10
        textfield.layer.borderWidth = 1
        textfield.layer.borderColor = UIColor.lightGray.cgColor
        textfield.placeholder = "Write your email"
        textfield.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        textfield.leftViewMode = .always
        textfield.backgroundColor = .white
        return textfield
    }()
    
    // 비밀번호 입력 필드
    private let passwordField : UITextField = {
        let textfield = UITextField()
        textfield.autocapitalizationType = .none
        textfield.autocorrectionType = .no
        textfield.returnKeyType = .done
        textfield.layer.cornerRadius = 10
        textfield.layer.borderWidth = 1
        textfield.layer.borderColor = UIColor.lightGray.cgColor
        textfield.placeholder = "Write your password"
        textfield.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        textfield.leftViewMode = .always
        textfield.backgroundColor = .white
        textfield.isSecureTextEntry = true
        return textfield
    }()
    
    // 로그인 버튼
    private let loginButton : UIButton = {
        let button = UIButton()
        button.setTitle("LogIn", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .link
        button.layer.cornerRadius = 10
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    // 페이스북 로그인 버튼
    private let faceBookLoginButton : FBLoginButton = {
       let button = FBLoginButton()
        // 페이스북 정보 필드 권한
        button.permissions = ["public_profile", "email"]
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Login"
        view.backgroundColor = .white
        
        // 오른쪽 탭바 버튼 -> 가입화면
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
                                                                 style: .done,
                                                                 target: self,
                                                                 action: #selector(didTapRegister))
        
        // 로그인 버튼 액션 추가
        self.loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        
        emailField.delegate = self
        passwordField.delegate = self
        faceBookLoginButton.delegate = self
        
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(faceBookLoginButton)
    }
    
    // 레이아웃이 결정되고 나서 수행
    // 1.다른 뷰들의 컨텐트 업데이트
    // 2.뷰들의 크기나 위치를 최종적으로 조정
    // 3.테이블의 데이터를 reload
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        
        let size = scrollView.width / 3
        imageView.frame = CGRect(x: (scrollView.width - size)/2,
                                 y: 20,
                                 width: size,
                                 height: size)
        
        emailField.frame = CGRect(x: 30,
                                  y: imageView.bottom + 10,
                                  width: scrollView.width - 60,
                                  height: 52)
        
        passwordField.frame = CGRect(x: 30,
                                     y: emailField.bottom + 10,
                                     width: scrollView.width - 60,
                                     height: 52)
        
        loginButton.frame = CGRect(x: 30,
                                   y: passwordField.bottom + 10,
                                   width: scrollView.width - 60,
                                   height: 52)
        
        faceBookLoginButton.frame = CGRect(x: 30,
                                   y: loginButton.bottom + 20,
                                   width: scrollView.width - 60,
                                   height: 52)
        
    }
    
    
    // 로그임 버튼 클릭 함수
    @objc private func loginButtonTapped() {
        // 이메일 필드, 비밀번호 필드 포커스 해제
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        // 이메일, 비밀번호 필드 확인
        guard let email = emailField.text, let password = passwordField.text, !email.isEmpty, !password.isEmpty, password.count >= 6 else {
            alertUserLoginError()
            return
        }
        
        spinner.show(in: view)
        
        // 이메일, 비밀번호로 로그인
        FirebaseAuth.Auth.auth().signIn(withEmail: email,
                                        password: password,
                                        completion: { [weak self] authResult, error in
                                            guard let self = self else {return}
                                            
                                            DispatchQueue.main.async {
                                                self.spinner.dismiss()
                                            }
                                            // 로그인 실패
                                            guard let result = authResult, error == nil else {
                                                print("fail login")
                                                return
                                            }
                                            // 로그인 성공
                                            let user = result.user
                                            
                                            UserDefaults.standard.set(email, forKey: "email")
                                            
                                            print("Logged in user \(user)")
                                            self.navigationController?.dismiss(animated: true, completion: nil)
                                        })
    }
    
    // 로그인 실패 알림
    @objc func alertUserLoginError() {
        let alert = UIAlertController(title: "로그인에 실패했습니다.",
                                      message: "다시 입력해주세요",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    
    // 상단 탭에 등록 버튼이 클릭되었을 때
    @objc private func didTapRegister() {
        let vc = RegisterViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
}


extension LoginViewController : UITextFieldDelegate {
    // 입력완료 버튼 설정
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        // emailfeild에서 return 키를 누르면 password field에 포커싱이 잡힌다.
        if textField == emailField {
            passwordField.becomeFirstResponder()
        }else if textField == passwordField {
            loginButtonTapped()
        }
        return true
    }
}

// MARK: -페이스북 로그인 delegate
extension LoginViewController : LoginButtonDelegate {
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        // no operation
    }
    
    // 페이스북 로그인이 완료된 후
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        // result에서 토큰 값 얻음
        guard let token = result?.token?.tokenString  else {
            if let error = error {
                print("fackebook login fail : \(error)")
            }
            return
        }
        
        // 페이스북으로 로그인한 이용자 정보 reqeust할 세부정보 작성
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me",
                                                         parameters: ["fields":"email, name, picture.type(large)"],
                                                         tokenString: token,
                                                         version: nil,
                                                         httpMethod: .get)
        
        // 이용자 정보 request후 response 수신
        facebookRequest.start{ _, result, error in
            guard let result = result as? [String: Any], error == nil else {
                print("fail to make facebook graph request")
                return
            }
            
            // response의 받은 데이터 언래핑
            guard let userName = result["name"] as? String,
                  let email = result["email"] as? String,
                  let picture = result["picture"] as? [String : Any],
                  let data = picture["data"] as? [String : Any],
                  let pictureUrl = data["url"] as? String
                else {
                print("Get user name and email fail")
                return
            }
            
            // 유저의 이메일을 전역 디폴트로 설정
            UserDefaults.standard.set(email, forKey: "email")
            
            // 페이스북 계정의 이메일과 일치하는 유저가 있는지 확인
            DatabaseManager.shared.userExists(with: email, completion: { exist in
                if exist == false{
                    let chatUser = ChatAppUser( firstName: userName,
                                                secondName: "",
                                                emailAddress: email
                                                )
                    // 이전에 등록된 동일한 이메일이 없다면 등록
                    DatabaseManager.shared.insertUser(with: chatUser, completion: { success in
                            if success {
                                guard let url = URL(string: pictureUrl) else { return }
                                print("LoginViewController - success download facebook userdata")
                                
                                // 프로필이미지 url request
                                let dataTask = URLSession.shared.dataTask(with: url){ data, status, error in
                                    guard let data = data else {
                                        print("LoginViewController - failed facebook insertUser \(String(describing: error))")
                                        return
                                    }
                                    
                                    print("LoginViewController - success facebook insertUser")
                                    
                                    //upload image to storage
                                    let fileName = chatUser.profilePictureFileName
                                    StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName, completion: { result in
                                        switch result {
                                        case .success(let downloadUrl):
                                            UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                            print(downloadUrl)
                                        case .failure(let error):
                                            print("Storage manager error :\(error)")
                                        }
                                    })
                                }
                                dataTask.resume()
                                
                            }
                    })
                }
            })
            
            // 페이스북으로 사용자가 로그인후 받은 토큰으로 credential 생성
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            // 생성된 credential로 firebase 로그인
            FirebaseAuth.Auth.auth().signIn(with: credential){ [weak self] authResult, error in
                guard let self = self else {return }
                
                guard authResult != nil, error == nil else {
                    if let error = error {
                        print("Facebook credectial login failed, MFA may be needed : \(error)")
                    }
                    return
                }
                
                print("Succefully logged in")
                self.navigationController?.dismiss(animated: true, completion: nil)
            }
            
        }
        
    }
    
    
}


