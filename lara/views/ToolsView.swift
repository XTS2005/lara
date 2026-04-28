//
//  ToolsView.swift
//  lara
//
//  Created by ruter on 04.04.26.
//

import SwiftUI

struct ToolsView: View {
    private enum tokenclass: String, CaseIterable, Identifiable {
        case read = "com.apple.app-sandbox.read"
        case write = "com.apple.app-sandbox.write"
        case readWrite = "com.apple.app-sandbox.read-write"

        var id: String { rawValue }

        var label: String {
            switch self {
            case .read: return "read"
            case .write: return "write"
            case .readWrite: return "read-write"
            }
        }
    }

    @ObservedObject private var mgr = laramgr.shared
    @State private var isaslr: Bool = aslrstate
    @State var showtoken: Bool = false
    @AppStorage("lara.sbx.issuedToken") private var token: String = ""
    @State private var issueclass: tokenclass = .readWrite
    @State private var issuepath: String = "/"
    @State private var uid: uid_t = getuid()
    @State private var pid: pid_t = getpid()
    @State private var status: String?
    
    var body: some View {
        List {
            if !mgr.dsready {
                Section {
                    Text("内核读写未就绪。请先运行漏洞。")
                        .foregroundColor(.secondary)
                } header: {
                    Text("状态")
                }
            }

            Section {
                HStack {
                    Text("ASLR：")
                    
                    Spacer()
                    
                    Text(isaslr ? "已启用" : "已禁用")
                        .foregroundColor(isaslr ? Color.red : Color.green)
                        .monospaced()
                    
                    Button {
                        isaslr = aslrstate
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                
                Button {
                    toggleaslr()
                    isaslr = aslrstate
                } label: {
                    Text("切换 ASLR")
                }
            } header: {
                Text("ASLR")
            } footer: {
                Text("ASLR（地址空间随机化）。这功能你大概率用不上。")
            }
            
            Section {
                Button("注销") {
                    mgr.respring()
                }
                
                HStack {
                    Text("ourproc：")
                    Spacer()
                    Text(mgr.dsready ? String(format: "0x%llx", ds_get_our_proc()) : "N/A")
                        .foregroundColor(.secondary)
                        .monospaced()
                }
                
                HStack {
                    Text("ourtask：")
                    Spacer()
                    Text(mgr.dsready ? String(format: "0x%llx", ds_get_our_task()) : "N/A")
                        .foregroundColor(.secondary)
                        .monospaced()
                }
                
                HStack {
                    Text("UID：")

                    Spacer()

                    Text("\(uid)")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)

                    Button {
                        uid = getuid()
                        print(uid)
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }

                HStack {
                    Text("PID：")
                    Spacer()

                    Text("\(pid)")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)

                    Button {
                        pid = getpid()
                        print(pid)
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            } header: {
                Text("进程")
            }

            Section {
                NavigationLink("LaraJIT") {
                    JitView()
                }
                .disabled(!mgr.dsready)
            } header: {
                Text("JIT")
            } footer: {
                Text("当前已失效。")
            }

            Section {
                Button {
                    if mgr.PPHelper() {
                        status = "操作已成功。请打开 Pocket Poster 应用，进入设置并轻点「检测」。"
                    } else {
                        status = "操作失败。请检查日志。"
                    }
                } label: {
                    Text("Pocket Poster 助手")
                }
                .disabled(!mgr.sbxready)
            } header: {
                Text("Pocket Poster")
            } footer: {
                Text("无需电脑即可获取 Pocket Poster 所需的哈希值。")
            }
            
            Section {
                HStack {
                    if showtoken {
                        Text(mgr.sbxready ? "tkn" : "无已保存的令牌。")
                            .foregroundColor(.secondary)
                            .monospaced()
                    } else {
                        if !token.isEmpty {
                            Text(token)
                                .foregroundColor(.secondary)
                                .monospaced()
                                .lineLimit(1)
                                .truncationMode(.middle)
                        } else {
                            Text("无已保存的令牌。")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button {
                        UIPasteboard.general.string = token.isEmpty ? nil : token
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                    .disabled(token.isEmpty)
                }
                .contextMenu {
                    if !token.isEmpty {
                        Button {
                            UIPasteboard.general.string = token
                        } label: {
                            Label("复制", systemImage: "doc.on.doc")
                        }
                    }
                }

                HStack {
                    Text("类别：")
                    Spacer()

                    Picker(" ", selection: $issueclass) {
                        ForEach(tokenclass.allCases) { tokenClass in
                            Text(tokenClass.label).tag(tokenClass)
                        }
                    }
                    .pickerStyle(.menu)
                }

                HStack {
                    Text("路径：")
                    Spacer()
                    
                    TextField("/", text: $issuepath)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .foregroundColor(.secondary)
                        .monospaced()
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .fixedSize(horizontal: true, vertical: false)
                }

                Button {
                    token = mgr.sbxissuetoken(extClass: issueclass.rawValue, path: issuepath) ?? ""
                } label: {
                    Text("签发令牌")
                }
                .disabled(!mgr.sbxready)
            } header: {
                Text("沙盒")
            }
        }
        .navigationTitle("工具")
        .alert("状态", isPresented: .constant(status != nil)) {
                Button("确定") { status = nil }
            } message: {
                Text(status ?? "")
            }
        .onAppear {
            if mgr.dsready {
                getaslrstate()
                isaslr = aslrstate
            }
        }
    }
}
