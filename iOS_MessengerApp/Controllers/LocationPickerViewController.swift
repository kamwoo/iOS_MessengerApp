//
//  LocationPickerViewController.swift
//  iOS_MessengerApp
//
//  Created by wooyeong kam on 2021/06/21.
//

import UIKit
import CoreLocation
import MapKit

final class LocationPickerViewController: UIViewController {
    
    // send버튼이 클릭되고 
    public var completion : ((CLLocationCoordinate2D) -> Void)?
    
    private var coordinates: CLLocationCoordinate2D?
    
    public var isPickable = true
    
    private let map : MKMapView = {
        let map = MKMapView()
        
        return map
    }()
    
    // 좌표가 들어 올 때, 안들어 올 때 구분하여 맵생성
    init(coordinates: CLLocationCoordinate2D?) {
        self.coordinates = coordinates
        self.isPickable = coordinates == nil
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Map"
        view.backgroundColor = .systemBackground
        // 위치를 보내는 메세지
        if isPickable{
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "보내기",
                                                                style: .done,
                                                                target: self,
                                                                action: #selector(sendButtonTapped))
            map.isUserInteractionEnabled = true
            let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapMap(_:)))
            gesture.numberOfTouchesRequired = 1
            gesture.numberOfTapsRequired = 1
            map.addGestureRecognizer(gesture)
            
        }else{ // 상대방 위치 메세지 확인할 때
            guard let coordinates = self.coordinates else {
                return
            }
            let pin = MKPointAnnotation()
            pin.coordinate = coordinates
            map.addAnnotation(pin)
        }
        
        view.addSubview(map)
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        map.frame = view.bounds
    }
    
    // 저장된 좌표보내고, dismiss
    @objc func sendButtonTapped(){
        guard let coordinates = coordinates else {
            return
        }
        
        navigationController?.popViewController(animated: true)
        completion?(coordinates)
    }
    
    // 지도에서 위치 클릭 했을 때
    @objc func didTapMap(_ gesture: UITapGestureRecognizer){
        // 화면 상의 좌표를 지구 좌표계로 변환
        let locationInView = gesture.location(in: map)
        let coordinates = map.convert(locationInView, toCoordinateFrom: map)
        self.coordinates = coordinates
        // 찍혀있는 핀 제거
        for annotation in map.annotations {
            map.removeAnnotation(annotation)
        }
        // 핀 찍음
        let pin = MKPointAnnotation()
        pin.coordinate = coordinates
        map.addAnnotation(pin)
    }


}
