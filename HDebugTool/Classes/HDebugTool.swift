//
//  HDebugTool.swift
//  HDebugTool
//
//  Created by HeXiaoTian on 2021/3/20.
//

import Foundation

@objcMembers
open class HDebugTool: NSObject {
    
    /**
     传入环境数据字典, 格式如: [String : [String : String]]
     ```swift
     [
         "dev":[
             "api": "http://baidu.com/api",
             "cas": "http://baidu.com/cas",
             "mqtt": "http://baidu.com/mqtt",
         ],
         "sit":[
             "api": "http://sit.com/api",
             "cas": "http://sit.com/cas",
             "mqtt": "http://sit.com/mqtt",
         ]
     ]
     ```
     */
    public static var envDatas = [
        "dev":[
            "api": "http://dev.com/api",
            "cas": "http://dev.com/cas",
            "mqtt": "http://dev.com/mqtt",
        ],
        "sit":[
            "api": "http://sit.com/api",
            "cas": "http://sit.com/cas",
            "mqtt": "http://sit.com/mqtt",
        ]
    ]
    /// 供测试选择的环境名称列表, 需要是 envDatas 中的 key
    public static var envNames = ["dev","sit"]
    /// 当前环境, 需要是 envNames 中的一个
    public static var currentEnv = "dev"
    /// 环境改变时回调
    public static var envChanged = {}
    /// 自定义设置项, 可添加自定义项到调试工具里面, 用于快速进行一些操作, 如添加一个退出登录项, 以便于测试时在任何界面快速登录新账号
    public static var settingItems: [SettingItem] = []
    
    
    static var debugBall = DebugBall(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
    
    public static func show() {
        guard let window = HDebugTool.getWindow() else { return }
        debugBall.center.y = window.center.y;
        debugBall.backgroundColor = UIColor.orange.withAlphaComponent(0.4)
        debugBall.layer.cornerRadius = 30
        debugBall.layer.borderColor = UIColor.orange.cgColor
        debugBall.layer.borderWidth = 1
        window.addSubview(debugBall)
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(moveToTop), userInfo: nil, repeats: true)
    }
    
    static func moveToTop() {
        guard let window = HDebugTool.getWindow() else { return }
        
        debugBall.evnNameLbl.text = self.currentEnv
        
        if window.subviews.last != debugBall {
            debugBall.removeFromSuperview()
            window.addSubview(debugBall)
        }
    }
    
    static func getWindow() -> UIWindow? {
        guard let window = UIApplication.shared.delegate?.window else { return nil }
        return window
    }
    
    static func getTopVC() -> UIViewController? {
        guard let window = HDebugTool.getWindow() else { return nil }
        
        var topVC = window.rootViewController
        while topVC?.presentedViewController != nil {
            topVC = topVC?.presentedViewController
        }
        return topVC
    }
    
}

public enum SettingItem {
    /// 可点击项, cell 带有一个右箭头
    case clickItem(title: String, detail: String, action: () -> Void)
    /// 带有一个切换开关 (UISwitch) 的 cell,
    /// 需要提供一个 UserDefaults 的 key, 按 bool 存取值,
    /// 显示 UISwitch 时会读取这个值, 点击切换时会写入到这个值
    case switchItem(title: String, UDKey: String, action: (Bool) -> Void)
}
