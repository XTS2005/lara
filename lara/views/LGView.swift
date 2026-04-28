//
//  LGView.swift
//  lara
//
//  Created by jurre111 on 24.04.26.
//

// Credits to leminlimez and Duy Tran for most of the code

import SwiftUI

struct LGView: View {
    @ObservedObject private var mgr = laramgr.shared
    @State private var gp: NSMutableDictionary
    @State private var status: String?
    @State private var valid: Bool = true
    
    private let path = "/var/Managed Preferences/mobile/.GlobalPreferences.plist"
    private let oggpurl: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        oggpurl = docs.appendingPathComponent("ogGlobalPreferences.plist")
        let sysurl = URL(fileURLWithPath: path)
        do {
            if !FileManager.default.fileExists(atPath: oggpurl.path) {
                try FileManager.default.copyItem(at: sysurl, to: oggpurl)
            }
            chmod(oggpurl.path, 0o644)
            
            _gp = State(initialValue: try NSMutableDictionary(contentsOf: URL(fileURLWithPath: path), error: ()))
        } catch {
            _gp = State(initialValue: [:])
            _status = State(initialValue: "拷贝 GlobalPreferences 失败：\(error)")
        }

    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("强制 Solarium 回退", isOn: gpkeybinding("SolariumForceFallback"))
                    Toggle("禁用液态玻璃", isOn: gpkeybinding("com.apple.SwiftUI.DisableSolarium"))
                    Toggle("忽略液态玻璃应用构建检查", isOn: gpkeybinding("com.apple.SwiftUI.IgnoreSolariumLinkedOnCheck"))
                    Toggle("禁用锁屏时钟液态玻璃", isOn: gpkeybinding("SBDisallowGlassTime"))
                    Toggle("禁用 Dock 液态玻璃", isOn: gpkeybinding("SBDisableGlassDock"))
                    Toggle("禁用镜面反射动效", isOn: gpkeybinding("SBDisableSpecularEverywhereUsingLSSAssertion"))
                    Toggle("禁用外部折射效果", isOn: gpkeybinding("SolariumDisableOuterRefraction"))
                    Toggle("禁用 Solarium HDR", isOn: gpkeybinding("SolariumAllowHDR", default: true, enable: false))
                } header: {
                    Text("液态玻璃")
                } footer: {
                    Text("注意：部分调整可能无效或导致不稳定。")
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
                        Text("刷新 plist")
                    }
                    Button() {
                        apply()
                    } label: {
                        Text("应用")
                    }
                    .disabled(!valid)
                } header: {
                    Text("操作")
                } footer: {
                    Text("请自行承担使用风险。务必始终将 \"/var/Managed Preferences/mobile/.GlobalPreferences.plist\" 备份至安全位置。")
                }
            }
            .navigationTitle("液态玻璃")
            .alert("状态", isPresented: .constant(status != nil)) {
                Button("确定") { status = nil }
            } message: {
                Text(status ?? "")
            }
            .onAppear(perform: load)
        }
    }
    
    private func validate(_ dict: NSMutableDictionary) -> Bool {
        return !dict.allKeys.isEmpty
    }

    private func load() {
        do {
            gp = try NSMutableDictionary(contentsOf: URL(fileURLWithPath: path), error: ())
        } catch {
            status = "加载 GlobalPreferences 失败"
        }

        valid = validate(gp)
    }

    private func apply() {
        if !validate(gp) {
            status = "Plist 无效。"
            return
        }
        do {
            let data = try PropertyListSerialization.data(
                fromPropertyList: gp,
                format: .binary,
                options: 0
            )
            
            let result = laramgr.shared.lara_overwritefile(
                target: path,
                data: data
            )
            if result.ok {
                load()
                if valid {
                    mgr.logmsg("overwrote GlobalPreferences.plist at \(path)")
                    status = "已应用 plist，重启以查看更改。"
                } else {
                    status = "已应用 plist 但无效。请勿注销，将备份 (lara/Documents/ogGlobalPreferences.plist) 复制到默认位置。"
                }
            } else {
                status = "覆盖失败：\(result.message)"
            }
            
        } catch {
            status = "序列化失败：\(error.localizedDescription)"
        }
    }
    
    private func gpkeybinding<T: Equatable>(_ key: String, type: T.Type = Bool.self, default: T? = false, enable: T? = true) -> Binding<Bool> {
        return Binding(
            get: {
                if let value = gp[key] as? T?, let enable {
                    return value == enable
                }
                return false
            },
            set: { enabled in
                if enabled {
                    gp[key] = enable
                } else {
                    gp.removeObject(forKey: key)
                }
                
                valid = validate(gp)
            }
        )
    }
}
