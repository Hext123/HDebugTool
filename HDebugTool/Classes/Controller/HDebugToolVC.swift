//
//  HDebugToolVC.swift
//  HDebugTool
//
//  Created by HeXiaoTian on 2021/3/21.
//

import UIKit

class HDebugToolVC: UITableViewController {
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var apiInfoLbl: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        segmentedControl.removeAllSegments()
        
        HDebugTool.envNames.reversed().forEach { name in
            segmentedControl.insertSegment(withTitle: name, at: 0, animated: true)
        }
        segmentedControl.selectedSegmentIndex = HDebugTool.envNames.firstIndex(of: HDebugTool.currentEnv) ?? 0
        self.envChanged(segmentedControl)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath {
        case IndexPath(row: 0, section: 1):
            self.navigationController?.pushViewController(HDebugFileManagerVC(), animated: true)
            break
        case IndexPath(row: 0, section: 2):
            self.clearUserDefaults()
            break
        case IndexPath(row: 1, section: 2):
            self.clearHomeDirectory()
            break
        default:
            break
        }
    }
    
    
    @IBAction func envChanged(_ sender: UISegmentedControl) {
        let envTitle = sender.titleForSegment(at: sender.selectedSegmentIndex)!
        var apiInfos = ""
        HDebugTool.envDatas[envTitle]!.forEach { (key: String, value: String) in
            apiInfos = "\(apiInfos)\(key)  \(value)\n"
        }
        apiInfoLbl.text = apiInfos
        self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
        
        if HDebugTool.currentEnv != envTitle {
            HDebugTool.currentEnv = envTitle
            HDebugTool.envChanged()
        }
    }
    
    /// 清空所有 UserDefaults
    func clearUserDefaults() {
        // 清除默认 UserDefaults
        let appDomain = Bundle.main.bundleIdentifier
        UserDefaults.standard.removePersistentDomain(forName: appDomain ?? "")
        UserDefaults.standard.synchronize()
        
        // 清除其它 UserDefaults
        var path = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).map(\.path).last
        path = URL(fileURLWithPath: path ?? "").appendingPathComponent("Preferences").path
        var fileList: [String]? = nil
        do {
            fileList = try FileManager.default.contentsOfDirectory(atPath: path ?? "")
        } catch {
        }
        
        for filename in fileList ?? [] {
            let filepath = URL(fileURLWithPath: path ?? "").appendingPathComponent(filename).path
            var isDir: ObjCBool = false
            FileManager.default.fileExists(atPath: filepath, isDirectory: &isDir)
            if !isDir.boolValue && filename.hasSuffix(".plist") && (filename != appDomain) {
                let suiteName = URL(fileURLWithPath: filename).deletingPathExtension().path
                let userDefaults = UserDefaults(suiteName: suiteName)
                userDefaults?.removePersistentDomain(forName: suiteName)
                do {
                    try FileManager.default.removeItem(atPath: filepath)
                } catch {
                }
            }
        }
    }
    
    /// 清空沙盒目录
    func clearHomeDirectory() {
        assert(UIDevice.current.userInterfaceIdiom == .phone || UIDevice.current.userInterfaceIdiom == .pad, "禁止在 iPhone 或 iPad 之外调用此方法, 比如在 Mac 上调用可能会删除整个用户目录 (模拟器除外)")
        // 双重保险判断
        switch UIDevice.current.userInterfaceIdiom {
        case .phone, .pad:
            break
        default:
            return
        }
        
        let cachePath = NSHomeDirectory()
        let files = FileManager.default.subpaths(atPath: cachePath)
        files?.forEach({ path in
            let cachePath : NSString = cachePath as NSString
            let fileAbsolutePath = cachePath.appendingPathComponent(path)
            if FileManager.default.fileExists(atPath: fileAbsolutePath) {
                try? FileManager.default.removeItem(atPath: fileAbsolutePath)
            }
        })
    }
    
}
