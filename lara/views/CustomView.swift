//
//  CustomView.swift
//  lara
//
//  Created by ruter on 29.03.26.
//

import SwiftUI
import UniformTypeIdentifiers

struct CustomView: View {
    @ObservedObject var mgr: laramgr
    @State private var targetPath: String = "/"
    @State private var showImporter = false
    @State private var sourcePath: String = ""
    @State private var sourceName: String = "未选择文件"
    @State private var isoverwriting = false

    var body: some View {
        List {
            Section {
                TextField("/path/to/target", text: $targetPath)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)

                HStack {
                    Text("源文件")
                    Spacer()
                    Text(sourceName)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Button("选择源文件") {
                    showImporter = true
                }

                Button(isoverwriting ? "覆盖中..." : "覆盖目标") {
                    guard !isoverwriting else { return }
                    overwrite()
                }
                .disabled(!canOverwrite)
            } header: {
                Text("自定义路径覆盖")
            } footer: {
                Text("这将用所选源文件的内容覆盖目标文件。目标文件大小必须大于等于源文件大小。")
            }

            Section {
                Text(globallogger.logs.last ?? "暂无日志")
                    .font(.system(size: 13, design: .monospaced))
            }
        }
        .navigationTitle("自定义覆盖")
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.item],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                importSource(url)
            }
        }
    }

    private var canOverwrite: Bool {
        mgr.vfsready && !targetPath.isEmpty && !sourcePath.isEmpty && !isoverwriting
    }

    private func importSource(_ url: URL) {
        let fm = FileManager.default
        let tmpDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let dest = tmpDir.appendingPathComponent("vfs_custom_\(UUID().uuidString)")

        do {
            if fm.fileExists(atPath: dest.path) {
                try fm.removeItem(at: dest)
            }
            try fm.copyItem(at: url, to: dest)
            sourcePath = dest.path
            sourceName = url.lastPathComponent
            mgr.logmsg("selected source: \(sourceName)")
        } catch {
            mgr.logmsg("failed to import source: \(error.localizedDescription)")
        }
    }

    private func overwrite() {
        guard canOverwrite else { return }
        isoverwriting = true
        DispatchQueue.global(qos: .userInitiated).async {
            let ok = mgr.vfsoverwritefromlocalpath(target: targetPath, source: sourcePath)
            DispatchQueue.main.async {
                isoverwriting = false
                ok ? mgr.logmsg("overwrite ok: \(targetPath)") : mgr.logmsg("overwrite failed: \(targetPath)")
            }
        }
    }
}

