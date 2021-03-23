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
            let alert = UIAlertController(title: "提示", message: "是否清除UserDefaults? 清除后APP需要重新登录", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "清除", style: .destructive, handler: { action in
                self.clearUserDefaults()
            }))
            HDebugTool.getTopVC()?.present(alert, animated: true, completion: nil)
            break
        case IndexPath(row: 1, section: 2):
            let alert = UIAlertController(title: "提示", message: "是否清除沙盒文件? 清除后APP几乎等同于全新安装", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "清除", style: .destructive, handler: { action in
                self.clearHomeDirectory()
            }))
            HDebugTool.getTopVC()?.present(alert, animated: true, completion: nil)
            break
        default:
            break
        }
    }
    
    
    @IBAction func envChanged(_ sender: UISegmentedControl) {
        guard let envTitle = sender.titleForSegment(at: sender.selectedSegmentIndex) else { return }
        guard let envData = HDebugTool.envDatas[envTitle] else { return }
        var apiInfos = ""
        envData.keys.sorted().enumerated().forEach { (index, key) in
            if index != 0  {
                apiInfos += "\n"
            }
            let value = envData[key]!
            if UIDevice.current.userInterfaceIdiom == .phone {
                apiInfos = "\(apiInfos)\(key)\n\(value)"
            } else {
                apiInfos = "\(apiInfos)\(key)\t\t\(value)"
            }
        }
        apiInfoLbl.text = apiInfos
        self.tableView.reloadData()
        
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
        
        
        let alert = UIAlertController(title: "提示", message: "UserDefaults已清空, 建议重启APP", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "重启", style: .destructive, handler: { action in
            self.exit()
        }))
        HDebugTool.getTopVC()?.present(alert, animated: true, completion: nil)
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
        
        let alert = UIAlertController(title: "提示", message: "沙盒文件已清空, 建议重启APP", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "重启", style: .destructive, handler: { action in
            self.exit()
        }))
        HDebugTool.getTopVC()?.present(alert, animated: true, completion: nil)
    }
    
    func exit() {
        if let window = HDebugTool.getWindow() {
            UIView.animate(withDuration: 0.3) {
                let center = window.center
                window.alpha = 0;
                window.frame = CGRect.zero;
                window.center = center;
            } completion: { finished in
                Darwin.exit(EXIT_SUCCESS)
            }
            
        } else {
            Darwin.exit(EXIT_SUCCESS)
        }
    }
    
}
