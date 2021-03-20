//
//  HDebugTool.swift
//  HDebugTool
//
//  Created by HeXiaoTian on 2021/3/20.
//

import Foundation

@objcMembers
public class HDebugTool: NSObject {
    
    static var debugBall = DebugBall(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
    
    public static func show() {
        guard let window = UIApplication.shared.delegate?.window else { return }
        guard let window = window else { return }
        debugBall.center.y = window.center.y;
        debugBall.backgroundColor = .orange.withAlphaComponent(0.4)
        debugBall.layer.cornerRadius = 30
        debugBall.layer.borderColor = UIColor.orange.cgColor
        debugBall.layer.borderWidth = 1
        window.addSubview(debugBall)
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(moveToTop), userInfo: nil, repeats: true)
    }
    
    static func moveToTop() {
        guard let window = UIApplication.shared.delegate?.window else { return }
        guard let window = window else { return }

        if window.subviews.last != debugBall {
            debugBall.removeFromSuperview()
            window.addSubview(debugBall)
        }
    }
}
