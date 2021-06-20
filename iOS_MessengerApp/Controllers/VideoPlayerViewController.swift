//
//  VideoPlayerViewController.swift
//  iOS_MessengerApp
//
//  Created by wooyeong kam on 2021/06/13.
//

import UIKit

class VideoPlayerViewController: UIViewController {
    
    private let url : URL

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    init(with url : URL){
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
