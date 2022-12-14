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
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(close))
        
        segmentedControl.removeAllSegments()
        
        HDebugTool.envNames.reversed().forEach { name in
            segmentedControl.insertSegment(withTitle: name, at: 0, animated: true)
        }
        segmentedControl.selectedSegmentIndex = HDebugTool.envNames.firstIndex(of: HDebugTool.currentEnv) ?? 0
        self.envChanged(segmentedControl)
    }
    
    @objc func close() {
        self.dismiss(animated: true)
    }
    
    @objc func valueChangedOfSwitch(_ accSwitch: UISwitch) {
        let settingItem = HDebugTool.settingItems[accSwitch.tag]
        if case let .switchItem(_, UDKey, action) = settingItem {
            UserDefaults.standard.set(accSwitch.isOn, forKey: UDKey)
            action(accSwitch.isOn)
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 3 {
            return HDebugTool.settingItems.count
        }
        return super.tableView(tableView, numberOfRowsInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 3 {
            let cell = UITableViewCell(style: .value1, reuseIdentifier: "custom_cell")
            switch HDebugTool.settingItems[indexPath.row] {
            case let .switchItem(title, UDKey, _):
                cell.textLabel?.text = title
                let accSwitch = UISwitch()
                accSwitch.isOn = UserDefaults.standard.bool(forKey: UDKey)
                accSwitch.tag = indexPath.row
                accSwitch.addTarget(self, action: #selector(valueChangedOfSwitch), for: .valueChanged)
                cell.accessoryView = accSwitch
            case let .clickItem(title, detail, _):
                cell.textLabel?.text = title
                cell.detailTextLabel?.text = detail
                cell.accessoryType = .disclosureIndicator
            }
            return cell
        }
        return super.tableView(tableView, cellForRowAt: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 3 {
            return UITableViewAutomaticDimension
        }
        return super.tableView(tableView, heightForRowAt: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath) -> Int {
        if indexPath.section == 3 {
            return super.tableView(tableView, indentationLevelForRowAt: IndexPath(row: 0, section: 3))
        }
        return super.tableView(tableView, indentationLevelForRowAt: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 3 {
            switch HDebugTool.settingItems[indexPath.row] {
            case let .clickItem(_, _, action):
                action()
            default: break
            }
            return
        }
        
        switch indexPath {
        case IndexPath(row: 0, section: 1):
            self.navigationController?.pushViewController(HDebugFileManagerVC(), animated: true)
            break
        case IndexPath(row: 0, section: 2):
            let alert = UIAlertController(title: "??????", message: "????????????UserDefaults? ?????????APP??????????????????", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "??????", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "??????", style: .destructive, handler: { action in
                self.clearUserDefaults()
            }))
            HDebugTool.getTopVC()?.present(alert, animated: true, completion: nil)
            break
        case IndexPath(row: 1, section: 2):
            let alert = UIAlertController(title: "??????", message: "????????????????????????? ?????????APP???????????????????????????", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "??????", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "??????", style: .destructive, handler: { action in
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
    
    /// ???????????? UserDefaults
    func clearUserDefaults(needAlert: Bool = true) {
        // ???????????? UserDefaults
        let appDomain = Bundle.main.bundleIdentifier
        UserDefaults.standard.removePersistentDomain(forName: appDomain ?? "")
        UserDefaults.standard.synchronize()
        
        // ???????????? UserDefaults
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
        
        if needAlert {
            let alert = UIAlertController(title: "??????", message: "UserDefaults?????????, ????????????APP", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "??????", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "??????", style: .destructive, handler: { action in
                self.exit()
            }))
            HDebugTool.getTopVC()?.present(alert, animated: true, completion: nil)
        }
    }
    
    /// ??????????????????
    func clearHomeDirectory() {
        precondition(UIDevice.current.userInterfaceIdiom == .phone || UIDevice.current.userInterfaceIdiom == .pad, "????????? iPhone ??? iPad ?????????????????????, ????????? Mac ?????????????????????????????????????????? (???????????????)")
        // ??????????????????
        switch UIDevice.current.userInterfaceIdiom {
        case .phone, .pad:
            break
        default:
            return
        }
        // ?????? UserDefaults, ??????????????? UserDefaults ?????????????????????
        self.clearUserDefaults(needAlert: false)
        
        let cachePath = NSHomeDirectory()
        let files = FileManager.default.subpaths(atPath: cachePath)
        files?.forEach({ path in
            let cachePath : NSString = cachePath as NSString
            let fileAbsolutePath = cachePath.appendingPathComponent(path)
            if FileManager.default.fileExists(atPath: fileAbsolutePath) {
                try? FileManager.default.removeItem(atPath: fileAbsolutePath)
            }
        })
        
        let alert = UIAlertController(title: "??????", message: "?????????????????????, ????????????APP", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "??????", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "??????", style: .destructive, handler: { action in
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
