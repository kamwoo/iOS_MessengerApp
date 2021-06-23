//
//  PhotoViewerViewController.swift
//  iOS_MessengerApp
//
//  Created by wooyeong kam on 2021/06/13.
//

import UIKit
import SDWebImage

final class PhotoViewerViewController: UIViewController {
    
    private let url : URL
    
    // 이미지 url
    init(with url: URL){
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 이미지 뷰 생성
    private let imageView : UIImageView = {
       let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        title = "Photo"
        navigationItem.largeTitleDisplayMode = .never
        view.addSubview(imageView)
        imageView.sd_setImage(with: url, completed: nil)
    }
    
    // 이미지뷰를 화면에 채움
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imageView.frame = view.bounds
    }
    
    
    
    
}
