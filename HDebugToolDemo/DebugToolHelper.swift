//
//  DebugToolHelper.swift
//  HDebugToolDemo
//
//  Created by HeXiaoTian on 2022/10/13.
//

import UIKit
import HDebugTool

@objcMembers
class DebugToolHelper: NSObject {
    class func settingItems() {
        HDebugTool.settingItems = [
            .switchItem(title: "夜间模式", UDKey: "", action: { value in
                print("点击了夜间模式开关", value)
            }),
            .clickItem(title: "退出登录", detail: "快速退出到登录界面", action: {
                print("点击了退出登录按钮")
            }),
        ]
    }
}
