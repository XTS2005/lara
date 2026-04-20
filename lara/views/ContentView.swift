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

    var body: some View {
        NavigationStack {
            List {
                if !hasoffsets {
                    Section("设置") {
                        Text("内核缓存偏移量缺失。请在设置中下载。")
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
                                        Text("漏洞已运行")
                                        Spacer()
                                        Image(systemName: "checkmark.circle")
                                            .foregroundColor(.green)
                                    }
                                } else if mgr.dsattempted && mgr.dsfailed {
                                    HStack {
                                        Text("漏洞利用失败")
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
                    } header: {
                        Text("内核读写")
                    } footer: {
                        if g_isunsupported {
                            Text("你的设备或安装方式可能不受支持。")
                        }
                        
                        if isdebugged() {
                            Text("连接调试器时不可用。")
                        }
                    }
                    .disabled(isdebugged())

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
                                        NavigationLink("字体覆盖") {
                                            FontPicker(mgr: mgr)
                                        }

                                        NavigationLink("卡片覆盖") {
                                            CardView()
                                        }

                                        NavigationLink("自定义覆盖") {
                                            CustomView(mgr: mgr)
                                        }

                                        NavigationLink("DirtyZero (已损坏)") {
                                            ZeroView(mgr: mgr)
                                        }

                                        if !showfmintabs {
                                            NavigationLink("文件管理器") {
                                                SantanderView(startPath: "/")
                                            }
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
                                        Text("正在沙盒逃逸...")
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
                                        Text("逃离沙盒")
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
                                        if !showfmintabs {
                                            NavigationLink("文件管理器") {
                                                SantanderView(startPath: "/")
                                            }
                                        }

                                        NavigationLink("卡片覆盖") {
                                            CardView()
                                        }

                                        NavigationLink("3 应用绕过") {
                                            AppsView(mgr: mgr)
                                        }

                                        NavigationLink("VarClean") {
                                            VarCleanView()
                                        }

                                        NavigationLink("解除黑名单 (已损坏?)") {
                                            WhitelistView()
                                        }

                                        if 1 == 2 {
                                            NavigationLink("MobileGestalt") {
                                                EditorView()
                                            }

                                            NavigationLink("密码主题") {
                                                PasscodeView(mgr: mgr)
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
                                            Text("正在沙盒逃逸...")
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
                                            Text("逃离沙盒")
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
                                        if !showfmintabs {
                                            NavigationLink("文件管理器") {
                                                SantanderView(startPath: "/")
                                            }
                                        }

                                        NavigationLink("字体覆盖") {
                                            FontPicker(mgr: mgr)
                                        }

                                        NavigationLink("卡片覆盖") {
                                            CardView()
                                        }

                                        NavigationLink("自定义覆盖") {
                                            CustomView(mgr: mgr)
                                        }

                                        NavigationLink("MobileGestalt") {
                                            EditorView()
                                        }

                                        NavigationLink("3 应用绕过") {
                                            AppsView(mgr: mgr)
                                        }

                                        NavigationLink("VarClean") {
                                            VarCleanView()
                                        }

                                        NavigationLink("白名单") {
                                            WhitelistView()
                                        }

                                        NavigationLink("DirtyZero") {
                                            ZeroView(mgr: mgr)
                                        }

                                        if 1 == 2 {
                                            NavigationLink("控制中心") {
                                                CCView()
                                            }

                                            NavigationLink("密码主题") {
                                                PasscodeView(mgr: mgr)
                                            }

                                            NavigationLink("3 应用绕过") {
                                                AppsView(mgr: mgr)
                                            }
                                        }
                                    }
                                    .navigationTitle(Text("调整"))
                                }
                            }
                        }
                    } header: {
                        Text(selectedmethod == .vfs ? "VFS" : (selectedmethod == .sbx ? "SBX" : "混合模式 (SBX + VFS)"))
                    } footer: {
                        if selectedmethod == .sbx {
                            Text("字体覆盖仅在 VFS 或混合模式下可用。(设置 -> 方法 -> VFS/混合)")
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

                        if mgr.rcready {
                            NavigationLink("调整") {
                                RemoteView(mgr: mgr)
                            }

                            Button("强制终止 RemoteCall") {
                                mgr.rcdestroy()
                            }
                        }
                    } header: {
                        Text("RemoteCall")
                    } footer: {
                        if isdebugged() {
                            Text("连接调试器时不可用。")
                        }
                        Text("RemoteCall 仍在开发中，可能无法始终正常工作。")
                    }
                    .disabled(isdebugged() || mgr.rcrunning)
                    #endif

                    Section {
                        if mgr.dsready {
                            NavigationLink("工具") {
                                ToolsView()
                            }
                        }

                        Button("重启桌面") {
                            mgr.respring()
                        }

                        Button("内核崩溃！") {
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
