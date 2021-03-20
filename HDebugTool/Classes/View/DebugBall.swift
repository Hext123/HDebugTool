//
//  DebugBall.swift
//  HDebugTool
//
//  Created by HeXiaoTian on 2021/3/20.
//

import Foundation

class DebugBall: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupView()
    }
    
    func setupView() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        self.addGestureRecognizer(panGesture)
        self.addGestureRecognizer(tapGesture)
    }
    
    @objc func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        guard let window = UIApplication.shared.delegate?.window else { return }
        guard let window = window else { return }
        
        let point = sender.location(in: nil)
        print(point)
        print(sender.state.rawValue)
        
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
        guard let window = UIApplication.shared.delegate?.window else { return }
        guard let window = window else { return }
        
        if sender.state == .ended {
            var rootViewController = window.rootViewController
            while rootViewController?.presentedViewController != nil {
                rootViewController = rootViewController?.presentedViewController
            }
            let vc = EnvSwitchVC(nibName: "EnvSwitchVC", bundle: Bundle(for: HDebugTool.self))
            let navC = UINavigationController(rootViewController: vc)
            rootViewController?.present(navC, animated: true, completion: nil)
        }
    }
    
}