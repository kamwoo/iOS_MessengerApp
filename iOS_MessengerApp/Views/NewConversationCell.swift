//
//  ConversationTableViewCell.swift
//  iOS_MessengerApp
//
//  Created by wooyeong kam on 2021/06/19.
//

import UIKit
import SDWebImage

class NewConversationCell: UITableViewCell {
    
    static let identifier = "NewConversationCell"
    
    // 대화셀에 표시될 상대 프로필 이미지
    private let userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 25
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    // 표시될 상대 유저 이름
    private let userNameLabel : UILabel = {
       let title = UILabel()
        title.font = UIFont.systemFont(ofSize: 21, weight: .semibold)
        return title
    }()
    

    override init(style: UITableViewCell.CellStyle, reuseIdentifier : String?){
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(userImageView)
        contentView.addSubview(userNameLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        userImageView.frame = CGRect(x: 10, y: 10, width: 50, height: 50)
        
        userNameLabel.frame = CGRect(x: userImageView.right + 10,
                                     y: 10,
                                     width: contentView.width - 20 - userImageView.width,
                                     height: contentView.height-20
        )
        
    }
    
    // id, name, 상대 이메일, 최근 메세지를 담은 Conversation 객체로 각 셀을 설정
    public func configure(with model : SearchResult){
        self.userNameLabel.text = model.name
        
        // 저장소에 있는 상대 유저 이미지 리턴
        let path = "images/\(model.email)_profile_picture.png"
        StorageManager.shared.downloadUrl(for: path, completion: { [weak self] result in
            switch result{
            case .success(let url):
                DispatchQueue.main.async {
                    self?.userImageView.sd_setImage(with: url, completed: nil)
                }
            case .failure(let error):
                print("failed to download Image \(error)")
            }
        })
    }

}
