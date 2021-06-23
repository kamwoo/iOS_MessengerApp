//
//  RegisterViewController.swift
//  iOS_MessengerApp
//
//  Created by wooyeong kam on 2021/06/13.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

final class RegisterViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    // MARK: - views
    private let scrollView : UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    // 프로필 이미지
    private let imageView : UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.circle")
        imageView.tintColor = .gray
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        return imageView
    }()
    
    // 이메일 필드
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
        textfield.backgroundColor = .secondarySystemBackground
        return textfield
    }()
    
    // 성 필드
    private let firstNameField : UITextField = {
        let textfield = UITextField()
        textfield.autocapitalizationType = .none
        textfield.autocorrectionType = .no
        textfield.returnKeyType = .continue
        textfield.layer.cornerRadius = 10
        textfield.layer.borderWidth = 1
        textfield.layer.borderColor = UIColor.lightGray.cgColor
        textfield.placeholder = "Write your first name"
        textfield.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        textfield.leftViewMode = .always
        textfield.backgroundColor = .secondarySystemBackground
        return textfield
    }()
    
    // 이름 필드
    private let secondNameField : UITextField = {
        let textfield = UITextField()
        textfield.autocapitalizationType = .none
        textfield.autocorrectionType = .no
        textfield.returnKeyType = .continue
        textfield.layer.cornerRadius = 10
        textfield.layer.borderWidth = 1
        textfield.layer.borderColor = UIColor.lightGray.cgColor
        textfield.placeholder = "Write your second name"
        textfield.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        textfield.leftViewMode = .always
        textfield.backgroundColor = .secondarySystemBackground
        return textfield
    }()
    
    // 비밀번호 필드
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
        textfield.backgroundColor = .secondarySystemBackground
        textfield.isSecureTextEntry = true
        return textfield
    }()
    
    // 등록 버튼
    private let registerButton : UIButton = {
        let button = UIButton()
        button.setTitle("Register", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemGreen
        button.layer.cornerRadius = 10
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Login"
        view.backgroundColor = .white
        
        registerButton.addTarget(self, action: #selector(registerButtonTapped), for: .touchUpInside)
        
        emailField.delegate = self
        passwordField.delegate = self
        
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(firstNameField)
        scrollView.addSubview(secondNameField)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(registerButton)
        
        // 이미지 클릭을 허용
        imageView.isUserInteractionEnabled = true
        scrollView.isUserInteractionEnabled = true
        
        // 이미지 클릭이 되었을 때
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapChangeProfileImage))
        imageView.addGestureRecognizer(gesture)
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
        imageView.layer.cornerRadius = imageView.width / 2
        
        firstNameField.frame = CGRect(x: 30,
                                  y: imageView.bottom + 10,
                                  width: scrollView.width - 60,
                                  height: 52)
        
        secondNameField.frame = CGRect(x: 30,
                                  y: firstNameField.bottom + 10,
                                  width: scrollView.width - 60,
                                  height: 52)
        
        emailField.frame = CGRect(x: 30,
                                  y: secondNameField.bottom + 10,
                                  width: scrollView.width - 60,
                                  height: 52)
        
        passwordField.frame = CGRect(x: 30,
                                     y: emailField.bottom + 10,
                                     width: scrollView.width - 60,
                                     height: 52)
        
        registerButton.frame = CGRect(x: 30,
                                   y: passwordField.bottom + 10,
                                   width: scrollView.width - 60,
                                   height: 52)
        
    }
    
    
    // MARK: -Button Actions
    
    // 이미지가 클릭되고 actionSheet 실행
    @objc private func didTapChangeProfileImage() {
        print("RegisterViewController - didTapChangeProfileImage() called")
        presentPhotoActionSheet()
    }
    
    
    
    // 등록 버튼이 클리되었을 때
    @objc private func registerButtonTapped() {
        
        // 포커싱 해제
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        firstNameField.resignFirstResponder()
        secondNameField.resignFirstResponder()
        
        // 각 텍스트 필드 평가 및 데이터 저장
        guard let firstName = firstNameField.text,
              let secondName = secondNameField.text,
              let email = emailField.text,
              let password = passwordField.text,
              !firstName.isEmpty,
              !secondName.isEmpty,
              !email.isEmpty,
              !password.isEmpty,
              password.count >= 6 else {
                    print("password error")
                    alertUserLoginError()
                    return
        }
        
        spinner.show(in: view)
        
        // 이전에 등록된 사용자가 있는지 확인
        DatabaseManager.shared.userExists(with: email){ [weak self] exist in
            guard let self = self else {return}
            
            DispatchQueue.main.async {
                self.spinner.dismiss()
            }
            
            // 값이 true면 유저가 있으므로 경고창 실행
            guard !exist else {
                // user already exist
                self.alertUserLoginError(message: "이미 존재하는 사용자입니다.")
                return
            }
            
            // Firebase Authentication에 등록
            FirebaseAuth.Auth.auth().createUser(withEmail: email,password: password, completion: { authResult, error in
                                                    
                guard authResult != nil, error == nil else {
                    print("RegisterViewController - createUser() auth error")
                    return
                }
                
                UserDefaults.standard.setValue(email, forKey: "email")
                UserDefaults.standard.setValue("\(firstName)\(secondName)", forKey: "name")
                
                // 가입 유저 정보
                let chatUser = ChatAppUser(firstName: firstName,
                                           secondName: secondName,
                                           emailAddress: email)
                // realtiem database에 저장
                DatabaseManager.shared.insertUser(with: chatUser, completion: { [weak self] success in
                    guard let self = self else {return}
                    if success {
                        //upload image
                        guard let image = self.imageView.image,
                              let data = image.pngData() else {
                            return
                        }
                        
                        let fileName = chatUser.profilePictureFileName
                        // 저장소에 프로필 이미지를 저장
                        StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName, completion: { result in
                            switch result {
                            case .success(let downloadUrl):
                                // 유저의 이메일을 전역으로 설정
                                UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                print(downloadUrl)
                            case .failure(let error):
                                print("Storage manager error :\(error)")
                            }
                        }) 
                    }
                })
                
                // RegisterView 종료
                self.navigationController?.dismiss(animated: true, completion: nil)
            })
            
        }
        
        
    }
    
    // 등록 실패 알림
    @objc func alertUserLoginError(message : String = "다시 입력해주세요" ) {
        let alert = UIAlertController(title: "등록에 실패했습니다.",
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    
}


// 입력이 완료 버튼 설정
extension RegisterViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        // emailfeild에서 return 키를 누르면 password field에 포커싱이 잡힌다.
        if textField == emailField {
            passwordField.becomeFirstResponder()
        }else if textField == passwordField {
            registerButtonTapped()
        }
        return true
    }
}

// 이미지 정보 등록 Delegate
extension RegisterViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func presentPhotoActionSheet() {
        let actionSheet = UIAlertController(title: "Profile Picture",
                                            message: "사진을 선택해주세요",
                                            preferredStyle: .actionSheet)
        // 취소 버튼
        actionSheet.addAction(UIAlertAction(title: "취소",
                                            style: .cancel,
                                            handler: nil))
        // 사진 찍기
        actionSheet.addAction(UIAlertAction(title: "사진찍기",
                                            style: .default,
                                            handler: { [weak self]_ in
                                                guard let self = self else {return}
                                                self.presentCamera()
                                            }))
        // 사진 선택
        actionSheet.addAction(UIAlertAction(title: "사진선택",
                                            style: .default,
                                            handler: { [weak self] _ in
                                                guard let self = self else {return}
                                                self.presentImagePicker()
                                            }))
        
        present(actionSheet, animated: true)
    }
    
    // 사진 촬영이 선택되었을 때 실행
    func presentCamera() {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true, completion: nil)
    }
    
    // 사진첩 선택 뷰 전환
    func presentImagePicker() {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true, completion: nil)
    }
    
    // 이미지가 선택되고 난 뒤
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {return}
        imageView.image = selectedImage
    }
    
    // 완료되고 종료될때
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
