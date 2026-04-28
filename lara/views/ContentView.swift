//
//  ContentView.swift
//  lara
//
//  Created by ruter on 23.03.26.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @AppStorage("showfmintabs") private var showfmintabs: Bool = true
    @ObservedObject private var mgr = laramgr.shared
    @State private var hasoffsets = true
    @State private var showsettings = false
    @State private var selectedmethod: method = .hybrid

    let os = ProcessInfo().operatingSystemVersion

    var body: some View {
        NavigationStack {
            List {
                if !hasoffsets {
                    Section("设置") {
                        Text("缺少 Kernelcache 偏移量。请在设置中下载。")
                            .foregroundColor(.secondary)
                        Button("打开设置") {
                            showsettings = true
                        }
                    }
                } else {
                    Section {
                        Button {
                            offsets_init()
                            mgr.run()
                        } label: {
                            if mgr.dsrunning {
                                HStack {
                                    ProgressView(value: mgr.dsprogress)
                                        .progressViewStyle(.circular)
                                        .frame(width: 18, height: 18)
                                    Text("运行中...")
                                    Spacer()
                                    Text("\(Int(mgr.dsprogress * 100))%")
                                }
                            } else {
                                if mgr.dsready {
                                    HStack {
                                        Text("已运行漏洞")
                                        Spacer()
                                        Image(systemName: "checkmark.circle")
                                            .foregroundColor(.green)
                                    }
                                } else if mgr.dsattempted && mgr.dsfailed {
                                    HStack {
                                        Text("漏洞运行失败")
                                        Spacer()
                                        Image(systemName: "xmark.circle")
                                            .foregroundColor(.red)
                                    }
                                } else {
                                    Text("运行漏洞")
                                }
                            }
                        }
                        .disabled(mgr.dsrunning)
                        .disabled(mgr.dsready)
                        .disabled(isdebugged())

                        if mgr.dsready {
                            HStack {
                                Text("kernel_base:")
                                Spacer()
                                Text(String(format: "0x%llx", mgr.kernbase))
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }

                            HStack {
                                Text("kernel_slide:")
                                Spacer()
                                Text(String(format: "0x%llx", mgr.kernslide))
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if isdebugged() {
                            Button {
                                exit(0)
                            } label: {
                                Text("分离")
                            }
                            .foregroundColor(.red)
                        }
                    } header: {
                        Text("内核读写")
                    } footer: {
                        if g_isunsupported {
                            Text("您的设备或安装方式可能不受支持。")
                        }
                        
                        if isdebugged() {
                            Text("调试器连接时不可用。")
                        }
                    }

                    Section {
                        if selectedmethod == .vfs {
                            Button {
                                mgr.vfsinit()
                            } label: {
                                if mgr.vfsrunning {
                                    HStack {
                                        ProgressView(value: mgr.vfsprogress)
                                            .progressViewStyle(.circular)
                                            .frame(width: 18, height: 18)
                                        Text("正在初始化 VFS...")
                                        Spacer()
                                        Text("\(Int(mgr.vfsprogress * 100))%")
                                    }
                                } else if !mgr.vfsready {
                                    if mgr.vfsattempted && mgr.vfsfailed {
                                        HStack {
                                            Text("VFS 初始化失败")
                                            Spacer()
                                            Image(systemName: "xmark.circle")
                                                .foregroundColor(.red)
                                        }
                                    } else {
                                        Text("初始化 VFS")
                                    }
                                } else {
                                    HStack {
                                        Text("VFS 已初始化")
                                        Spacer()
                                        Image(systemName: "checkmark.circle")
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                            .disabled(!mgr.dsready || mgr.vfsready || mgr.vfsrunning)

                            if mgr.vfsready {
                                NavigationLink("调整") {
                                    List {
                                        Section {
                                            NavigationLink {
                                                FontPicker(mgr: mgr)
                                            } label: {
                                                Label("字体覆盖", systemImage: "textformat.alt")
                                            }

                                            NavigationLink {
                                                CardView()
                                            } label: {
                                                Label("卡片覆盖", systemImage: "creditcard")
                                            }

                                            NavigationLink {
                                                ZeroView(mgr: mgr)
                                            } label: {
                                                Label("DirtyZero", systemImage: "doc")
                                            }
                                        } header: {
                                            Text("界面调整")
                                        }

                                        Section {
                                            if !showfmintabs {
                                                NavigationLink {
                                                    SantanderView(startPath: "/")
                                                } label: {
                                                    Label("文件管理器", systemImage: "folder")
                                                }
                                            }
                                            
                                            NavigationLink {
                                                CustomView(mgr: mgr)
                                            } label: {
                                                Label("自定义覆盖", systemImage: "pencil")
                                            }
                                        } header: {
                                            Text("其他")
                                        }
                                    }
                                    .navigationTitle(Text("调整"))
                                }
                            }
                        } else if selectedmethod == .sbx {
                            Button {
                                mgr.sbxescape()
                                // mgr.sbxelevate()
                            } label: {
                                if mgr.sbxrunning {
                                    HStack {
                                        ProgressView()
                                            .progressViewStyle(.circular)
                                            .frame(width: 18, height: 18)
                                        Text("正在逃逸沙盒...")
                                    }
                                } else if !mgr.sbxready {
                                    if mgr.sbxattempted && mgr.sbxfailed {
                                        HStack {
                                            Text("沙盒逃逸失败")
                                            Spacer()
                                            Image(systemName: "xmark.circle")
                                                .foregroundColor(.red)
                                        }
                                    } else {
                                        Text("逃逸沙盒")
                                    }
                                } else {
                                    HStack {
                                        Text("已沙盒逃逸")
                                        Spacer()
                                        Image(systemName: "checkmark.circle")
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                            .disabled(!mgr.dsready || mgr.sbxready || mgr.sbxrunning)

                            if mgr.sbxready {
                                NavigationLink("调整") {
                                    List {
                                        Section {
                                            NavigationLink {
                                                CardView()
                                            } label: {
                                                Label("卡片覆盖", systemImage: "creditcard")
                                            }
                                        } header: {
                                            Text("界面调整")
                                        }

                                        Section {
                                            NavigationLink {
                                                AppsView(mgr: mgr)
                                            } label: {
                                                Label(" 3 应用绕过", systemImage: "lock.open.fill")
                                            }

                                            NavigationLink {
                                                WhitelistView()
                                            } label: {
                                                Label("移除黑名单（已失效？）", systemImage: "checkmark.seal")
                                            }
                                        } header: {
                                            Text("应用管理")
                                        }

                                        Section {
                                            if !showfmintabs {
                                                NavigationLink {
                                                    SantanderView(startPath: "/")
                                                } label: {
                                                    Label("文件管理器", systemImage: "folder")
                                                }
                                            }

                                            NavigationLink {
                                                VarCleanView()
                                            } label: {
                                                Label("VarClean", systemImage: "sparkles")
                                            }
                                        } header: {
                                            Text("其他")
                                        }

                                        if 1 == 2 {
                                            NavigationLink {
                                                EditorView()
                                            } label: {
                                                Label("MobileGestalt", systemImage: "gear")
                                            }
                                            NavigationLink {
                                                PasscodeView(mgr: mgr)
                                            } label: {
                                                Label("密码主题", systemImage: "1.circle")
                                            }
                                        }
                                    }
                                    .navigationTitle(Text("调整"))
                                }
                            }
                        } else {
                            if !mgr.sbxattempted {
                                Button {
                                    mgr.sbxescape()
                                } label: {
                                    if mgr.sbxrunning {
                                        HStack {
                                            ProgressView()
                                                .progressViewStyle(.circular)
                                                .frame(width: 18, height: 18)
                                            Text("正在逃逸沙盒...")
                                        }
                                    } else if !mgr.sbxready {
                                        if mgr.sbxattempted && mgr.sbxfailed {
                                            HStack {
                                                Text("沙盒逃逸失败")
                                                Spacer()
                                                Image(systemName: "xmark.circle")
                                                    .foregroundColor(.red)
                                            }
                                        } else {
                                            Text("逃逸沙盒")
                                        }
                                    } else {
                                        HStack {
                                            Text("已沙盒逃逸")
                                            Spacer()
                                            Image(systemName: "checkmark.circle")
                                                .foregroundColor(.green)
                                        }
                                    }
                                }
                                .disabled(!mgr.dsready || mgr.sbxready || mgr.sbxrunning)
                            } else {
                                Button {
                                    mgr.vfsinit()
                                } label: {
                                    if mgr.vfsrunning {
                                        HStack {
                                            ProgressView(value: mgr.vfsprogress)
                                                .progressViewStyle(.circular)
                                                .frame(width: 18, height: 18)
                                            Text("正在初始化 VFS...")
                                            Spacer()
                                            Text("\(Int(mgr.vfsprogress * 100))%")
                                        }
                                    } else if !mgr.vfsready {
                                        if mgr.vfsattempted && mgr.vfsfailed {
                                            HStack {
                                                Text("VFS 初始化失败")
                                                Spacer()
                                                Image(systemName: "xmark.circle")
                                                    .foregroundColor(.red)
                                            }
                                        } else {
                                            Text("初始化 VFS")
                                        }
                                    } else {
                                        HStack {
                                            Text("混合模式已初始化")
                                            Spacer()
                                            Image(systemName: "checkmark.circle")
                                                .foregroundColor(.green)
                                        }
                                    }
                                }
                                .disabled(!mgr.dsready || mgr.vfsready || mgr.vfsrunning)
                            }

                            if mgr.vfsready && mgr.sbxready {
                                NavigationLink("调整") {
                                    List {
                                        Section {
                                            NavigationLink {
                                                FontPicker(mgr: mgr)
                                            } label: {
                                                Label("字体覆盖", systemImage: "textformat.alt")
                                            }

                                            NavigationLink {
                                                CardView()
                                            } label: {
                                                Label("卡片覆盖", systemImage: "creditcard")
                                            }

                                            NavigationLink {
                                                ZeroView(mgr: mgr)
                                            } label: {
                                                Label("DirtyZero", systemImage: "doc")
                                            }
                                            
                                        if 1 == 2 {
                                            NavigationLink {
                                                DarkBoardView()
                                            } label: {
                                                Label("DarkBoard", systemImage: "app.badge")
                                            }
                                        }
                                        
                                            if os.majorVersion >= 26 {
                                                NavigationLink {
                                                    LGView()
                                                } label: {
                                                    Label("液态玻璃", systemImage: "capsule")
                                                }
                                            }
                                        } header: {
                                            Text("界面调整")
                                        }
                                        Section {
                                            NavigationLink {
                                                AppsView(mgr: mgr)
                                            } label: {
                                                Label(" 3 应用绕过", systemImage: "lock.open.fill")
                                            }
                                            NavigationLink {
                                                WhitelistView()
                                            } label: {
                                                Label("移除黑名单（已失效？）", systemImage: "checkmark.seal")
                                            }
                                        } header: {
                                            Text("应用管理")
                                        }
                                        Section {
                                            if !showfmintabs {
                                                NavigationLink {
                                                    SantanderView(startPath: "/")
                                                } label: {
                                                    Label("文件管理器", systemImage: "folder")
                                                }
                                            }

                                            NavigationLink {
                                                CustomView(mgr: mgr)
                                            } label: {
                                                Label("自定义覆盖", systemImage: "pencil")
                                            }

                                            NavigationLink {
                                                EditorView()
                                            } label: {
                                                Label("MobileGestalt", systemImage: "gear")
                                            }

                                            NavigationLink {
                                                VarCleanView()
                                            } label: {
                                                Label("VarClean", systemImage: "sparkles")
                                            }
                                        } header: {
                                            Text("其他")
                                        }

                                        if 1 == 2 {
                                            NavigationLink("控制中心") {
                                                CCView()
                                            }

                                            NavigationLink("密码主题") {
                                                PasscodeView(mgr: mgr)
                                            }
                                        }
                                    }
                                    .navigationTitle(Text("调整"))
                                }
                            }
                        }
                    } header: {
                        Text(selectedmethod == .vfs ? "VFS" : (selectedmethod == .sbx ? "SBX" : "混合模式（SBX + VFS）"))
                    } footer: {
                        if selectedmethod == .sbx {
                            Text("字体覆盖仅在 VFS 或混合模式下可用。（设置 → 模式 → VFS/混合）")
                        }
                    }

                    #if !DISABLE_REMOTECALL
                    Section {
                        Button {
                            mgr.logmsg("T")
                            mgr.rcinit(process: "SpringBoard", migbypass: false) { success in
                                if success {
                                    mgr.logmsg("rc init succeeded!")
                                    let pid = mgr.rccall(name: "getpid")
                                    mgr.logmsg("remote getpid() returned: \(pid)")
                                } else {
                                    mgr.logmsg("rc init failed")
                                }
                            }
                        } label: {
                            if mgr.rcrunning {
                                Text("正在初始化 RemoteCall...")
                            } else if !mgr.rcready {
                                Text("初始化 RemoteCall")
                            } else {
                                HStack {
                                    Text("RemoteCall 已初始化")
                                    Spacer()
                                    Image(systemName: "checkmark.circle")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        .disabled(!mgr.dsready || mgr.rcready)
                        .disabled(isdebugged())

                        if mgr.rcready {
                            NavigationLink("调整") {
                                RemoteView(mgr: mgr)
                            }

                            Button("终止 RemoteCall") {
                                mgr.rcdestroy()
                            }
                        }
                        
                        if isdebugged() {
                            Button {
                                exit(0)
                            } label: {
                                Text("分离")
                            }
                            .foregroundColor(.red)
                        }
                    } header: {
                        Text("RemoteCall")
                    } footer: {
                        if let error = mgr.rcLastError ?? mgr.sbProc?.lastError {
                            Text("RemoteCall 错误：\(error)")
                                .foregroundColor(.red)
                        }
                        if RemoteCall.isLiveContainerRuntime() && !RemoteCall.isLiveProcessRuntime() {
                            Text("RemoteCall 需要启用 PAC 的 LiveContainer 环境下才能跑。当 RemoteCall 不可用时，主漏洞可能仍可正常工作。")
                        }
                        if isdebugged() {
                            Text("调试器连接时不可用。")
                        }
                        Text("RemoteCall 仍在开发中，可能无法始终正常工作。")
                    }
                    .disabled(mgr.rcrunning)
                    #endif

                    Section {
                        if mgr.dsready {
                            NavigationLink("工具") {
                                ToolsView()
                            }
                        }

                        Button("注销") {
                            mgr.respring()
                        }

                        Button("重启") {
                            mgr.panic()
                        }
                        .disabled(!mgr.dsready)
                    } header: {
                        Text("其他")
                    }
                }

            }
            .navigationTitle("lara")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showsettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
        }
        .sheet(isPresented: $showsettings) {
            SettingsView(mgr: mgr, hasoffsets: $hasoffsets)
        }
        .onAppear {
            refreshselectedmethod()
        }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            refreshselectedmethod()
        }
    }

    private func refreshselectedmethod() {
        if let raw = UserDefaults.standard.string(forKey: "selectedmethod"),
           let m = method(rawValue: raw) {
            selectedmethod = m
        }
    }
}
