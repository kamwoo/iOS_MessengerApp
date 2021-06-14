//
//  NewConversationViewController.swift
//  iOS_MessengerApp
//
//  Created by wooyeong kam on 2021/06/13.
//

import UIKit
import JGProgressHUD

// 새로운 대화만들기 뷰

class NewConversationViewController: UIViewController {
    
    private let spinner = JGProgressHUD()
    
    // 상단 대화상대 찾기 검색바 생성
    private let searchBar : UISearchBar = {
       let searchBar = UISearchBar()
        searchBar.placeholder = "대화할 상대를 선택해주세요..."
        return searchBar
    }()
    
    // 테이블 뷰, 사람이 없다면 보이지 않는다.
    private let tableView : UITableView = {
       let table = UITableView()
        table.isHidden = true
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return table
    }()
    
    // 사람이 없을 때 보여질 뷰
    private let noResultsLabel: UILabel = {
       let label = UILabel()
        label.isHidden = true
        label.text = "검색 결과가 없습니다."
        label.textAlignment = .center
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 21, weight: .medium)
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 네비게이션 상단을 검색바 아이템으로 설정
        navigationController?.navigationBar.topItem?.titleView = searchBar
        // 검색 취소 버튼 생성
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancle",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(dismissSelf))
        // 검색창으로 넘어오고, 바로 검색바에 포커싱한다.
        searchBar.becomeFirstResponder()
    }
    
    // 창닫기
    @objc private func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }

}


extension NewConversationViewController : UISearchBarDelegate {
    // 검색 버튼이 클릭되고 액션
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
    }
}

