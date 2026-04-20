//
//  SettingsView.swift
//  lara
//
//  Created by ruter on 29.03.26.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var mgr: laramgr
    @Binding var hasoffsets: Bool
    @State private var showresetalert: Bool = false
    @State private var downloadingkernelcache = false
    @State private var showingKernelcacheImporter: Bool = false
    @State private var importingkernelcache: Bool = false
    @AppStorage("loggernobullshit") private var loggernobullshit: Bool = true
    @AppStorage("keepalive") private var iskeepalive: Bool = true
    @AppStorage("showfmintabs") private var showfmintabs: Bool = true
    @AppStorage("selectedmethod") private var selectedmethod: method = .hybrid
    @AppStorage("rcdockunlimited") private var rcdockunlimited: Bool = false
    
    var appname: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? "未知应用"
    }
    var appversion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }
    var appicon: UIImage {
        if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let files = primary["CFBundleIconFiles"] as? [String],
           let last = files.last,
           let image = UIImage(named: last) {
            return image
        }
        
        return UIImage(named: "unknown") ?? UIImage()
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 12) {
                        Image(uiImage: appicon)
                            .resizable()
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        VStack(alignment: .leading) {
                            Text(appname)
                                .font(.headline)
                            
                            Text("版本 \(appversion)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Lara")
                }
                
                
                Section {
                    Picker("", selection: $selectedmethod) {
                        ForEach(method.allCases, id: \.self) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("方法")
                } footer: {
                    if selectedmethod == .vfs {
                        Text("仅 VFS。")
                    } else if selectedmethod == .sbx {
                        Text("仅 SBX。")
                    } else {
                        Text("混合：SBX 用于读取，VFS 用于写入。\n有史以来最好的方法。(感谢 Huy)")
                    }
                }
                
                Section {
                    Toggle("禁用日志分隔符", isOn: $loggernobullshit)
                        .onChange(of: loggernobullshit) { _ in
                            globallogger.clear()
                        }
                    
                    Toggle("保持后台活跃", isOn: $iskeepalive)
                        .onChange(of: iskeepalive) { _ in
                            if iskeepalive {
                                if !kaenabled { toggleka() }
                            } else {
                                if kaenabled { toggleka() }
                            }
                        }
                    
                    Toggle("在标签页中显示文件管理器", isOn: $showfmintabs)

                } header: {
                    Text("Lara 设置")
                } footer: {
                    Text(""保持后台活跃"可使应用在最小化（而非从应用切换器中关闭）时继续在后台运行。")
                }

                #if !DISABLE_REMOTECALL
                Section {
                    Toggle("允许超过10个Dock栏图标", isOn: $rcdockunlimited)
                } header: {
                    Text("RemoteCall")
                } footer: {
                    Text("在 RemoteCall 调整中启用更大的 Dock 栏列数。")
                }
                #endif

                Section {
                    if !hasoffsets {
                        Button("下载内核缓存") {
                            guard !downloadingkernelcache else { return }
                            downloadingkernelcache = true
                            DispatchQueue.global(qos: .userInitiated).async {
                                let ok = dlkerncache()
                                DispatchQueue.main.async {
                                    hasoffsets = ok
                                    downloadingkernelcache = false
                                }
                            }
                        }
                        .disabled(downloadingkernelcache)
                        
                        Button("获取内核缓存") {
                            mgr.run()
                        }
                        
                        Button("从文件导入内核缓存") {
                            guard !importingkernelcache else { return }
                            showingKernelcacheImporter = true
                        }
                        .disabled(importingkernelcache)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("如何获取内核缓存 (macOS)")
                                .font(.footnote.weight(.semibold))
                                .foregroundColor(.primary)

                            Text("1. 为你的设备下载 IPSW 工具。")
                            Link("https://github.com/blacktop/ipsw/releases",
                                 destination: URL(string: "https://github.com/blacktop/ipsw/releases")!)

                            Text("2. 解压归档文件。")
                            Text("3. 打开终端。")
                            Text("4. 导航至解压后的文件夹：")
                            Text("cd /path/to/ipsw_3.1.671_something_something/")
                                .font(.system(.caption2, design: .monospaced))
                                .textSelection(.enabled)

                            Text("5. 提取内核：")
                            Text("./ipsw extract --kernel [将你的 ipsw 文件拖到此处]")
                                .font(.system(.caption2, design: .monospaced))
                                .textSelection(.enabled)

                            Text("6. 获取 kernelcache 文件。")
                            Text("7. 将 kernelcache 传输到你的 iCloud 或 iPhone。")
                            Text("8. 点击上方按钮并选择 kernelcache 文件，例如 kernelcache.release.iPhone14,3。")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                    }
                    
                    Button {
                        showresetalert = true
                    } label: {
                        Text("删除内核缓存数据")
                            .foregroundColor(.red)
                    }
                } header: {
                    Text("内核缓存")
                } footer: {
                    Text("删除并重新下载内核缓存可以解决许多问题。在提交 GitHub Issue 之前请先尝试此操作。")
                }
                
                Section {
                    HStack(alignment: .top) {
                        AsyncImage(url: URL(string: "https://github.com/rooootdev.png")) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading) {
                            Text("roooot")
                                .font(.headline)
                            
                            Text("主要开发者")
                                .font(.subheadline)
                                .foregroundColor(Color.secondary)
                        }
                        
                        Spacer()
                    }
                    .onTapGesture {
                        if let url = URL(string: "https://github.com/rooootdev"),
                           UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    }
                    
                    HStack(alignment: .top) {
                        AsyncImage(url: URL(string: "https://github.com/wh1te4ever.png")) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading) {
                            Text("wh1te4ever")
                                .font(.headline)
                            
                            Text("让 darksword-kexploit 变得有趣。")
                                .font(.subheadline)
                                .foregroundColor(Color.secondary)
                        }
                        
                        Spacer()
                    }
                    .onTapGesture {
                        if let url = URL(string: "https://github.com/wh1te4ever"),
                           UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    }
                    
                    HStack(alignment: .top) {
                        AsyncImage(url: URL(string: "https://github.com/AppInstalleriOSGH.png")) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading) {
                            Text("AppInstaller iOS")
                                .font(.headline)
                            
                            Text("在偏移量和许多其他方面帮助了我。没有他，这个项目不可能完成！")
                                .font(.subheadline)
                                .foregroundColor(Color.secondary)
                        }
                        
                        Spacer()
                    }
                    .onTapGesture {
                        if let url = URL(string: "https://github.com/AppInstalleriOSGH"),
                           UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    }
                    
                    HStack(alignment: .top) {
                        AsyncImage(url: URL(string: "https://github.com/jailbreakdotparty.png")) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading) {
                            Text("jailbreak.party")
                                .font(.headline)
                            
                            Text("所有的 DirtyZero 调整和精神支持。")
                                .font(.subheadline)
                                .foregroundColor(Color.secondary)
                        }
                        
                        Spacer()
                    }
                    .onTapGesture {
                        if let url = URL(string: "https://github.com/jailbreakdotparty"),
                           UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    }
                    
                    HStack(alignment: .top) {
                        AsyncImage(url: URL(string: "https://github.com/neonmodder123.png")) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading) {
                            Text("neon")
                                .font(.headline)
                            
                            Text("制作了 respring 脚本。")
                                .font(.subheadline)
                                .foregroundColor(Color.secondary)
                        }
                        
                        Spacer()
                    }
                    .onTapGesture {
                        if let url = URL(string: "https://github.com/neonmodder123"),
                           UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    }
                } header: {
                    Text("致谢")
                }
            }
            .navigationTitle("设置")
        }
        .fileImporter(isPresented: $showingKernelcacheImporter,
                      allowedContentTypes: [.data],
                      allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                importingkernelcache = true
                DispatchQueue.global(qos: .userInitiated).async {
                    var ok = false
                    let shouldStopAccess = url.startAccessingSecurityScopedResource()
                    defer {
                        if shouldStopAccess {
                            url.stopAccessingSecurityScopedResource()
                        }
                    }
                    let fm = FileManager.default
                    if let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first {
                        let dest = docs.appendingPathComponent("kernelcache")
                        do {
                            if fm.fileExists(atPath: dest.path) {
                                try fm.removeItem(at: dest)
                            }
                            try fm.copyItem(at: url, to: dest)
                            ok = dlkerncache()
                        } catch {
                            print("导入内核缓存失败：\(error)")
                            ok = false
                        }
                    }
                    DispatchQueue.main.async {
                        hasoffsets = ok
                        importingkernelcache = false
                    }
                }
            case .failure:
                break
            }
        }
        .alert("清除内核缓存数据？", isPresented: $showresetalert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                clearkerncachedata()
                //hasoffsets = haskernproc()
            }
        } message: {
            Text("这将删除已下载的内核缓存并移除保存的偏移量。")
        }
    }
}

enum method: String, CaseIterable {
    case vfs = "VFS"
    case sbx = "SBX"
    case hybrid = "混合"
}
