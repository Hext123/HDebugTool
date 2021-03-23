//
//  DebugBall.swift
//  HDebugTool
//
//  Created by HeXiaoTian on 2021/3/20.
//

import Foundation

class DebugBall: UIView {
    
    let evnNameLbl = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupView()
    }
    
    func setupView() {
        evnNameLbl.frame = self.bounds
        evnNameLbl.textAlignment = .center
        self.addSubview(evnNameLbl)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        self.addGestureRecognizer(panGesture)
        self.addGestureRecognizer(tapGesture)
    }
    
    @objc func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        guard let window = HDebugTool.getWindow() else { return }
        
        let point = sender.location(in: nil)
        
        switch sender.state {
        case .possible, .began, .changed:
            // 拖动手势进行中
            self.center = point
        case .ended, .cancelled, .failed, .recognized:
            // 拖动手势已结束
            var boundsPoint = point
            if boundsPoint.x > window.center.x {
                boundsPoint.x = window.bounds.width - self.frame.width / 2;
            } else {
                boundsPoint.x = 0 + self.frame.width / 2;
            }
            UIView.animate(withDuration: 0.2) {
                self.center = boundsPoint
            }
        }
    }
    
    @objc func handleTapGesture(_ sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            let rootViewController = HDebugTool.getTopVC()
            let navC = UIStoryboard.init(name: "HDebugTool", bundle: Bundle(for: HDebugTool.self)).instantiateInitialViewController();
            rootViewController?.present(navC!, animated: true, completion: nil)
        }
    }
    
}
