//
//  EditorView.swift
//  lara
//
//  Created by ruter on 27.03.26.
//

// Most of the code is from Duy's SparseBox
// thank you @jurre111

import SwiftUI

struct EditorView: View {
    @ObservedObject private var mgr = laramgr.shared
    @State private var mg: NSMutableDictionary
    @State private var status: String?
    @State private var alert: String?
    @State private var valid: Bool = true
    @AppStorage("ogSubType") private var ogSubType: Int = -1
    @State private var selectedSubType: Int = -1

    enum SubType: Int, CaseIterable, Identifiable {
        case iPhone14Pro = 2556
        case iPhone14ProMax = 2796
        case iPhone16Pro = 2622
        case iPhone16ProMax = 2868
        // X gestures for SE?

        var id: Int { self.rawValue }
        var displayName: String {
            switch self {
            case .iPhone14Pro: return "14 Pro (2556)"
            case .iPhone14ProMax: return "14 Pro Max (2796)"
            case .iPhone16Pro: return "iOS 18+:\n16 Pro (2622)"
            case .iPhone16ProMax: return "iOS 18+:\n16 Pro Max (2868)"
            }
        }
    }
    
    private let path = "/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/com.apple.MobileGestalt.plist"
    private let ogmgurl: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        ogmgurl = docs.appendingPathComponent("ogmobilegestalt.plist")
        let sysurl = URL(fileURLWithPath: path)
        do {
            if !FileManager.default.fileExists(atPath: ogmgurl.path) {
                try FileManager.default.copyItem(at: sysurl, to: ogmgurl)
            }
            chmod(ogmgurl.path, 0o644)
            
            _mg = State(initialValue: try NSMutableDictionary(contentsOf: URL(fileURLWithPath: path), error: ()))
        } catch {
            _mg = State(initialValue: [:])
            _status = State(initialValue: "复制 MobileGestalt 失败：\(error)")
        }
        guard let cacheExtra = mg["CacheExtra"] as? NSMutableDictionary, let oPeik = cacheExtra["oPeik/9e8lQWMszEjbPzng"] as? NSMutableDictionary else {
            _status = State(initialValue: "无法从 MobileGestalt 获取字典。请重新打开页面。")
            return
        }
        guard let subType = oPeik["ArtworkDeviceSubType"] as? Int else {
            _status = State(initialValue: "无法从 MobileGestalt 获取 SubType。请重新打开页面。")
            return
        }
        _selectedSubType = State(initialValue: subType)
        // This only happens on the first load
        if ogSubType == -1 {
            ogSubType = subType
        }

    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("灵动岛")
                        
                        Spacer()
                        
                        Picker("", selection: $selectedSubType) {
                            Text("默认 (\(String(ogSubType)))").tag(ogSubType)
                            ForEach(SubType.allCases.filter { $0.rawValue != ogSubType }) { subtype in
                                Text(subtype.displayName).tag(subtype.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    Toggle("操作按钮 (17+)", isOn: mgkeybinding(["cT44WE1EohiwRzhsZ8xEsw"]))
                    Toggle("允许安装 iPadOS 应用", isOn: mgkeybinding(["9MZ5AdH43csAUajl/dU+IQ"], type: [Int].self, default: [1], enable: [1, 2]))
                    Toggle("全天候显示 (18.0+)", isOn: mgkeybinding(["j8/Omm6s1lsmTDFsXjsBfA", "2OOJf1VhaM7NxfRok3HbWQ"]))
                    // Toggle("Apple Intelligence", isOn: bindingForAppleIntelligence())
                    //    .disabled(requiresVersion(18))
                    Toggle("Apple Pencil", isOn: mgkeybinding(["yhHcB0iH0d1XzPO/CFd3ow"]))
                    Toggle("启动铃声", isOn: mgkeybinding(["QHxt+hGLaBPbQJbXiUJX3w"]))
                    Toggle("相机按钮 (18.0rc+)", isOn: mgkeybinding(["CwvKxM2cEogD3p+HYgaW0Q", "oOV1jhJbdV3AddkcCg0AEA"]))
                    Toggle("充电上限 (17+)", isOn: mgkeybinding(["37NVydb//GP/GrhuTN+exg"]))
                    Toggle("车祸检测 (可能无效)", isOn: mgkeybinding(["HCzWusHQwZDea6nNhaKndw"]))
                    // Toggle("Dynamic Island (17.4+, might not work)", isOn: mgkeybinding(["YlEtTtHlNesRBMal1CqRaA"]))
                    // Toggle("Disable region restrictions", isOn: bindingForRegionRestriction())
                    Toggle("内部存储信息", isOn: mgkeybinding(["LBJfwOEzExRxzlAnSuI7eg"]))
                    // Toggle("Internal stuff", isOn: bindingForInternalStuff())
                    Toggle("Apple 安全性研究设备", isOn: mgkeybinding(["XYlJKKkj2hztRP1NWWnhlw"]))
                    Toggle("所有应用显示 Metal HUD", isOn: mgkeybinding(["EqrsVvjcYDdxHBiQmGhAWw"]))
                    Toggle("台前调度 (仅 iPad?)", isOn: mgkeybinding(["qeaj75wk3HF4DwQ8qbIi7g"]))
                        .disabled(UIDevice.current.userInterfaceIdiom != .pad)
                    if UIDevice._hasHomeButton() {
                        Toggle("Tap to Wake (iPhone SE)", isOn: mgkeybinding(["yZf3GTRMGTuwSV/lD7Cagw"]))
                    }
                } header: {
                    Text("MobileGestalt")
                } footer: {
                    Text("注意：部分调整可能无效或导致不稳定。\n警告：切勿启用设备不支持的功能。")
                }
                Section {
                    let cacheExtra = mg["CacheExtra"] as? NSMutableDictionary
                    Toggle("伪装 iPadOS", isOn: bindingForTrollPad())
                    // validate DeviceClass
                        .disabled(cacheExtra?["+3Uf0Pm5F8Xy7Onyvko0vA"] as? String != "iPhone")
                } footer: {
                    Text("将用户界面风格覆盖为 iPadOS，以便在 iPhone 上使用所有 iPadOS 多任务功能。提供与 TrollPad 相同的能力，但可能导致一些问题。\n请不要关闭台前调度中的显示 Dock，否则横屏时手机将无限重启。")
                }
                Section {
                    HStack {
                        Text("状态")
                        
                        Spacer()
                        
                        if valid {
                            Text("有效！")
                                .monospaced(true)
                                .foregroundColor(.green)
                        } else {
                            Text("无效。")
                                .monospaced(true)
                                .foregroundColor(.red)
                        }
                    }
                    Button() {
                        load()
                    } label: {
                        Text("重新加载 plist")
                    }
                    Button() {
                        apply()
                    } label: {
                        Text("应用修改后的 MobileGestalt")
                    }
                    .disabled(!valid)
                } header: {
                    Text("应用")
                } footer: {
                    Text("风险自负。请务必备份 MobileGestalt 到安全位置。")
                }
                
                HStack(alignment: .top) {
                    AsyncImage(url: URL(string: "https://github.com/jurre111.png")) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    
                    VStack(alignment: .leading) {
                        Text("Jurre")
                            .font(.headline)
                        
                        Text("整个 EditorView。")
                            .font(.subheadline)
                            .foregroundColor(Color.secondary)
                    }
                    
                    Spacer()
                }
                .onTapGesture {
                    if let url = URL(string: "https://github.com/jurre111"),
                       UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                }
            }
            .navigationTitle("MobileGestalt")
            .alert("状态", isPresented: .constant(status != nil)) {
                Button("确定") { status = nil }
            } message: {
                Text(status ?? "")
            }
            .alert("完成", isPresented: .constant(alert != nil)) {
                Button("取消") { alert = nil }
                Button("注销") {
                    alert = nil
                    mgr.respring()
                }
            } message: {
                Text(alert ?? "呃...")
            }
            .onAppear(perform: load)
        }
    }
    
    private func validate(_ dict: NSMutableDictionary) -> Bool {
        guard let cacheExtra = dict["CacheExtra"] as? NSMutableDictionary else { return false }
        return !cacheExtra.allKeys.isEmpty
    }

    private func load() {
        do {
            mg = try NSMutableDictionary(contentsOf: URL(fileURLWithPath: path), error: ())
        } catch {
            status = "加载 mobilegestalt 失败"
        }
    }

    private func apply() {
        do {
            if selectedSubType != -1 {
                guard let cacheExtra = mg["CacheExtra"] as? NSMutableDictionary, let oPeik = cacheExtra["oPeik/9e8lQWMszEjbPzng"] as? NSMutableDictionary else {
                    status = "无法从 MobileGestalt 获取字典。"
                    return
                }
                oPeik["ArtworkDeviceSubType"] = selectedSubType
            } else {
                status = "所选 SubType 为 -1？请重新加载页面。"
                return
            }
            let data = try PropertyListSerialization.data(
                fromPropertyList: mg,
                format: .binary,
                options: 0
            )
            
            let result = laramgr.shared.lara_overwritefile(
                target: path,
                data: data
            )
            
            if result.ok {
                mgr.logmsg("overwrote MobileGestalt at \(path)")
                alert = "已应用修改后的 mobilegestalt，注销后生效。"
            } else {
                status = "覆盖失败：\(result.message)"
            }
            
        } catch {
            status = "序列化失败：\(error.localizedDescription)"
        }
    }
    private func bindingForTrollPad() -> Binding<Bool> {
        // We're going to overwrite DeviceClassNumber but we can't do it via CacheExtra, so we need to do it via CacheData instead
        guard let cacheData = mg["CacheData"] as? NSMutableData,
              let cacheExtra = mg["CacheExtra"] as? NSMutableDictionary else {
            return State(initialValue: false).projectedValue
        }
        let valueOffset = FindCacheDataOffset("mtrAoWJ3gsq+I90ZnQ0vQw")
        //print("Read value from \(cacheData.mutableBytes.load(fromByteOffset: valueOffset, as: Int.self))")
        
        let keys = [
            "uKc7FPnEO++lVhHWHFlGbQ", // ipad
            "mG0AnH/Vy1veoqoLRAIgTA", // MedusaFloatingLiveAppCapability
            "UCG5MkVahJxG1YULbbd5Bg", // MedusaOverlayAppCapability
            "ZYqko/XM5zD3XBfN5RmaXA", // MedusaPinnedAppCapability
            "nVh/gwNpy7Jv1NOk00CMrw", // MedusaPIPCapability,
            "qeaj75wk3HF4DwQ8qbIi7g", // DeviceSupportsEnhancedMultitasking
        ]
        return Binding(
            get: {
                if let value = cacheExtra[keys.first!] as? Int? {
                    return value == 1
                }
                return false
            },
            set: { enabled in
                if enabled {
                    status = "伪装 iPadOS 是有风险的功能，请注意以下事项：\n\n1. 仅限 iOS 的应用（如 WhatsApp）可能会丢失数据。建议卸载这些应用。\n2. 如果主屏幕有空位，布局可能会乱掉。\n3. 如果您使用字母密码，锁屏后很难解锁手机。\n4. 台前调度中任何与 Dock 相关的选项都不应修改。\n\n仅在您接受这些风险时继续。否则请点击重新加载 plist 。"
                }
                cacheData.mutableBytes.storeBytes(of: enabled ? 3 : 1, toByteOffset: valueOffset, as: Int.self)
                for key in keys {
                    if enabled {
                        cacheExtra[key] = 1
                    } else {
                        // just remove the key as it will be pulled from device tree if missing
                        cacheExtra.removeObject(forKey: key)
                    }
                }
                
                valid = validate(mg)
            }
        )
    }
    
    private func mgkeybinding<T: Equatable>(_ keys: [String], type: T.Type = Int.self, default: T? = 0, enable: T? = 1) -> Binding<Bool> {
        guard let cachextra = mg["CacheExtra"] as? NSMutableDictionary else {
            return State(initialValue: false).projectedValue
        }
        
        return Binding(
            get: {
                if let value = cachextra[keys.first!] as? T?, let enable {
                    return value == enable
                }
                return false
            },
            set: { enabled in
                for key in keys {
                    if enabled {
                        cachextra[key] = enable
                    } else {
                        cachextra.removeObject(forKey: key)
                    }
                }
                
                valid = validate(mg)
            }
        )
    }
}
