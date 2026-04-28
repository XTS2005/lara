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
    @State private var showkcacheimporter: Bool = false
    @State private var importingkernelcache: Bool = false
    @State private var showkcachetips: Bool = false
    @State private var statusmsg: String?
    @AppStorage("loggernobullshit") private var loggernobullshit: Bool = true
    @AppStorage("keepalive") private var iskeepalive: Bool = true
    @AppStorage("showfmintabs") private var showfmintabs: Bool = true
    @AppStorage("selectedmethod") private var selectedmethod: method = .hybrid
    @AppStorage("rcdockunlimited") private var rcdockunlimited: Bool = false
    @AppStorage("stashkrw") private var stashkrw: Bool = false
    @AppStorage("selectedFmAppsDisplayMode") private var selectedFmAppsDisplayMode: fmAppsDisplayMode = .appName
    @AppStorage("fmRecursiveSearch") private var fmRecursiveSearch: Bool = false
    
    var appname: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? "Unknown App"
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
    private var t1szbootbind: Binding<String> {
        Binding(
            get: {
                String(format: "0x%llx", t1sz_boot)
            },
            set: { newval in
                let cleaned = newval
                    .replacingOccurrences(of: "0x", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                if let value = UInt64(cleaned, radix: 16) {
                    t1sz_boot = value
                    UserDefaults.standard.set(value, forKey: "lara.t1sz_boot")
                    UserDefaults.standard.synchronize()
                }
            }
        )
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
                    Text("模式")
                } footer: {
                    if selectedmethod == .vfs {
                        Text("仅 VFS。")
                    } else if selectedmethod == .sbx {
                        Text("仅 SBX。")
                    } else {
                        Text("混合：SBX 用于读取，VFS 用于写入。\n最佳模式。（感谢 Huy）")
                    }
                }
                
                Section {
                    Toggle("禁用日志分隔符", isOn: $loggernobullshit)
                        .onChange(of: loggernobullshit) { _ in
                            globallogger.clear()
                        }
                    
                    Toggle("保持活跃", isOn: $iskeepalive)
                        .onChange(of: iskeepalive) { _ in
                            if iskeepalive {
                                if !kaenabled { toggleka() }
                            } else {
                                if kaenabled { toggleka() }
                            }
                        }
                    
                    Toggle("在标签页中显示文件管理器", isOn: $showfmintabs)
                    Toggle("在文件管理器中启用深度搜索", isOn: $fmRecursiveSearch)
                } header: {
                    Text("Lara 设置")
                } footer: {
                    Text("「保持活跃」可在应用最小化时使其继续在后台运行。")
                }

                Section {
                    Picker("显示模式", selection: $selectedFmAppsDisplayMode) {
                        ForEach(fmAppsDisplayMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("文件管理器应用管理")
                } footer: {
                    Text("更改应用文件夹在文件管理器中的显示方式。")
                }

                #if !DISABLE_REMOTECALL
                Section {
                    Toggle("缓存 KRW 原语", isOn: $stashkrw)
                    Toggle("允许超过10个Dock栏图标", isOn: $rcdockunlimited)
                } header: {
                    Text("RemoteCall")
                }
                #endif

                Section {
                    if !hasoffsets {
                        Button("下载 Kernelcache") {
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
                        
                        Button("获取 Kernelcache") {
                            mgr.run()
                        }
                        
                        HStack {
                            Button("从文件导入 Kernelcache") {
                                guard !importingkernelcache else { return }
                                showkcacheimporter = true
                            }
                            .disabled(importingkernelcache)
                            
                            Spacer()
                            
                            Button {
                                showkcachetips.toggle()
                            } label: {
                                Image(systemName: "lightbulb.max.fill")
                            }
                        }
                    }
                    
                    Button {
                        showresetalert = true
                    } label: {
                        Text("删除 Kernelcache 数据")
                            .foregroundColor(.red)
                    }
                } header: {
                    Text("Kernelcache")
                } footer: {
                    if !showkcachetips {
                        Text("删除并重新下载 Kernelcache 可以解决许多问题。在提交 GitHub Issue 之前请先尝试此操作。")
                    }
                }
                
                if showkcachetips {
                    Section {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("如何获取 kernelcache（macOS）")
                                .font(.footnote.weight(.semibold))
                                .foregroundColor(.primary)
                            
                            Text("1. 下载适用于您设备的 IPSW 工具。")
                            Link("https://github.com/blacktop/ipsw/releases",
                                 destination: URL(string: "https://github.com/blacktop/ipsw/releases")!)
                            
                            Text("2. 解压压缩包。")
                            Text("3. 打开终端。")
                            Text("4. 导航到解压后的文件夹：")
                            Text("cd /path/to/ipsw_3.1.671_something_something/")
                                .font(.system(.caption2, design: .monospaced))
                                .textSelection(.enabled)
                                .foregroundColor(.primary)
                            
                            Text("5. 提取内核：")
                            Text("./ipsw extract --kernel [drag your ipsw here]")
                                .font(.system(.caption2, design: .monospaced))
                                .textSelection(.enabled)
                                .foregroundColor(.primary)
                            
                            Text("6. 获取 kernelcache 文件。")
                            Text("7. 将 kernelcache 传输到您的 iCloud 或 iPhone。")
                            Text("8. 点击上方按钮并选择 kernelcache 文件，例如 kernelcache.release.iPhone14,3。")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                    } footer: {
                        Text("删除并重新下载 Kernelcache 可以解决许多问题。在提交 GitHub Issue 之前请先尝试此操作。")
                    }
                }
                
                if isdebugged() {
                    Section {
                        Button {
                            exit(0)
                        } label: {
                            Text("分离")
                        }
                        .foregroundColor(.red)
                    } header: {
                        Text("调试器")
                    } footer: {
                        Text("调试器连接时 Lara 无法工作。")
                    }
                }
                
                Section {
                    NavigationLink("修改偏移量") {
                        List {
                            HStack { Text("off_inpcb_inp_list_le_next"); Spacer(); Text(hex(UInt64(off_inpcb_inp_list_le_next))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_inpcb_inp_pcbinfo"); Spacer(); Text(hex(UInt64(off_inpcb_inp_pcbinfo))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_inpcb_inp_socket"); Spacer(); Text(hex(UInt64(off_inpcb_inp_socket))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_inpcbinfo_ipi_zone"); Spacer(); Text(hex(UInt64(off_inpcbinfo_ipi_zone))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_inpcb_inp_depend6_inp6_icmp6filt"); Spacer(); Text(hex(UInt64(off_inpcb_inp_depend6_inp6_icmp6filt))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_inpcb_inp_depend6_inp6_chksum"); Spacer(); Text(hex(UInt64(off_inpcb_inp_depend6_inp6_chksum))).foregroundColor(.secondary).monospaced() }
                            
                            HStack { Text("off_socket_so_usecount"); Spacer(); Text(hex(UInt64(off_socket_so_usecount))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_socket_so_proto"); Spacer(); Text(hex(UInt64(off_socket_so_proto))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_socket_so_background_thread"); Spacer(); Text(hex(UInt64(off_socket_so_background_thread))).foregroundColor(.secondary).monospaced() }
                            
                            HStack { Text("off_kalloc_type_view_kt_zv_zv_name"); Spacer(); Text(hex(UInt64(off_kalloc_type_view_kt_zv_zv_name))).foregroundColor(.secondary).monospaced() }
                            
                            HStack { Text("off_thread_t_tro"); Spacer(); Text(hex(UInt64(off_thread_t_tro))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_thread_ro_tro_proc"); Spacer(); Text(hex(UInt64(off_thread_ro_tro_proc))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_thread_ro_tro_task"); Spacer(); Text(hex(UInt64(off_thread_ro_tro_task))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_thread_machine_upcb"); Spacer(); Text(hex(UInt64(off_thread_machine_upcb))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_thread_machine_contextdata"); Spacer(); Text(hex(UInt64(off_thread_machine_contextdata))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_thread_ctid"); Spacer(); Text(hex(UInt64(off_thread_ctid))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_thread_options"); Spacer(); Text(hex(UInt64(off_thread_options))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_thread_mutex_lck_mtx_data"); Spacer(); Text(hex(UInt64(off_thread_mutex_lck_mtx_data))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_thread_machine_kstackptr"); Spacer(); Text(hex(UInt64(off_thread_machine_kstackptr))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_thread_guard_exc_info_code"); Spacer(); Text(hex(UInt64(off_thread_guard_exc_info_code))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_thread_mach_exc_info_code"); Spacer(); Text(hex(UInt64(off_thread_mach_exc_info_code))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_thread_mach_exc_info_os_reason"); Spacer(); Text(hex(UInt64(off_thread_mach_exc_info_os_reason))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_thread_mach_exc_info_exception_type"); Spacer(); Text(hex(UInt64(off_thread_mach_exc_info_exception_type))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_thread_ast"); Spacer(); Text(hex(UInt64(off_thread_ast))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_thread_task_threads_next"); Spacer(); Text(hex(UInt64(off_thread_task_threads_next))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_thread_machine_jop_pid"); Spacer(); Text(hex(UInt64(off_thread_machine_jop_pid))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_thread_machine_rop_pid"); Spacer(); Text(hex(UInt64(off_thread_machine_rop_pid))).foregroundColor(.secondary).monospaced() }
                            
                            HStack { Text("off_proc_p_list_le_next"); Spacer(); Text(hex(UInt64(off_proc_p_list_le_next))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_proc_p_list_le_prev"); Spacer(); Text(hex(UInt64(off_proc_p_list_le_prev))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_proc_p_proc_ro"); Spacer(); Text(hex(UInt64(off_proc_p_proc_ro))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_proc_p_pid"); Spacer(); Text(hex(UInt64(off_proc_p_pid))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_proc_p_fd"); Spacer(); Text(hex(UInt64(off_proc_p_fd))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_proc_p_flag"); Spacer(); Text(hex(UInt64(off_proc_p_flag))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_proc_p_textvp"); Spacer(); Text(hex(UInt64(off_proc_p_textvp))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_proc_p_name"); Spacer(); Text(hex(UInt64(off_proc_p_name))).foregroundColor(.secondary).monospaced() }
                            
                            HStack { Text("off_proc_ro_pr_task"); Spacer(); Text(hex(UInt64(off_proc_ro_pr_task))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_proc_ro_p_ucred"); Spacer(); Text(hex(UInt64(off_proc_ro_p_ucred))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_ucred_cr_label"); Spacer(); Text(hex(UInt64(off_ucred_cr_label))).foregroundColor(.secondary).monospaced() }
                            
                            HStack { Text("off_task_itk_space"); Spacer(); Text(hex(UInt64(off_task_itk_space))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_task_threads_next"); Spacer(); Text(hex(UInt64(off_task_threads_next))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_task_task_exc_guard"); Spacer(); Text(hex(UInt64(off_task_task_exc_guard))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_task_map"); Spacer(); Text(hex(UInt64(off_task_map))).foregroundColor(.secondary).monospaced() }
                            
                            HStack { Text("off_filedesc_fd_ofiles"); Spacer(); Text(hex(UInt64(off_filedesc_fd_ofiles))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_filedesc_fd_cdir"); Spacer(); Text(hex(UInt64(off_filedesc_fd_cdir))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_fileproc_fp_glob"); Spacer(); Text(hex(UInt64(off_fileproc_fp_glob))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_fileglob_fg_data"); Spacer(); Text(hex(UInt64(off_fileglob_fg_data))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_fileglob_fg_flag"); Spacer(); Text(hex(UInt64(off_fileglob_fg_flag))).foregroundColor(.secondary).monospaced() }
                            
                            HStack { Text("off_vnode_v_ncchildren_tqh_first"); Spacer(); Text(hex(UInt64(off_vnode_v_ncchildren_tqh_first))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_vnode_v_nclinks_lh_first"); Spacer(); Text(hex(UInt64(off_vnode_v_nclinks_lh_first))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_vnode_v_parent"); Spacer(); Text(hex(UInt64(off_vnode_v_parent))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_vnode_v_data"); Spacer(); Text(hex(UInt64(off_vnode_v_data))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_vnode_v_name"); Spacer(); Text(hex(UInt64(off_vnode_v_name))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_vnode_v_usecount"); Spacer(); Text(hex(UInt64(off_vnode_v_usecount))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_vnode_v_iocount"); Spacer(); Text(hex(UInt64(off_vnode_v_iocount))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_vnode_v_writecount"); Spacer(); Text(hex(UInt64(off_vnode_v_writecount))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_vnode_v_flag"); Spacer(); Text(hex(UInt64(off_vnode_v_flag))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_vnode_v_mount"); Spacer(); Text(hex(UInt64(off_vnode_v_mount))).foregroundColor(.secondary).monospaced() }
                            
                            HStack { Text("off_mount_mnt_flag"); Spacer(); Text(hex(UInt64(off_mount_mnt_flag))).foregroundColor(.secondary).monospaced() }
                            
                            HStack { Text("off_namecache_nc_vp"); Spacer(); Text(hex(UInt64(off_namecache_nc_vp))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_namecache_nc_child_tqe_next"); Spacer(); Text(hex(UInt64(off_namecache_nc_child_tqe_next))).foregroundColor(.secondary).monospaced() }
                            
                            HStack { Text("off_arm_saved_state64_lr"); Spacer(); Text(hex(UInt64(off_arm_saved_state64_lr))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_arm_saved_state64_pc"); Spacer(); Text(hex(UInt64(off_arm_saved_state64_pc))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_arm_saved_state_uss_ss_64"); Spacer(); Text(hex(UInt64(off_arm_saved_state_uss_ss_64))).foregroundColor(.secondary).monospaced() }
                            
                            HStack { Text("off_ipc_space_is_table"); Spacer(); Text(hex(UInt64(off_ipc_space_is_table))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_ipc_entry_ie_object"); Spacer(); Text(hex(UInt64(off_ipc_entry_ie_object))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_ipc_port_ip_kobject"); Spacer(); Text(hex(UInt64(off_ipc_port_ip_kobject))).foregroundColor(.secondary).monospaced() }
                            
                            HStack { Text("off_arm_kernel_saved_state_sp"); Spacer(); Text(hex(UInt64(off_arm_kernel_saved_state_sp))).foregroundColor(.secondary).monospaced() }
                            
                            HStack { Text("off_vm_map_hdr"); Spacer(); Text(hex(UInt64(off_vm_map_hdr))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_vm_map_header_nentries"); Spacer(); Text(hex(UInt64(off_vm_map_header_nentries))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_vm_map_entry_links_next"); Spacer(); Text(hex(UInt64(off_vm_map_entry_links_next))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_vm_map_entry_vme_object_or_delta"); Spacer(); Text(hex(UInt64(off_vm_map_entry_vme_object_or_delta))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_vm_map_entry_vme_alias"); Spacer(); Text(hex(UInt64(off_vm_map_entry_vme_alias))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_vm_map_header_links_next"); Spacer(); Text(hex(UInt64(off_vm_map_header_links_next))).foregroundColor(.secondary).monospaced() }
                            
                            HStack { Text("off_vm_object_vo_un1_vou_size"); Spacer(); Text(hex(UInt64(off_vm_object_vo_un1_vou_size))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_vm_object_ref_count"); Spacer(); Text(hex(UInt64(off_vm_object_ref_count))).foregroundColor(.secondary).monospaced() }
                            
                            HStack { Text("off_vm_named_entry_backing_copy"); Spacer(); Text(hex(UInt64(off_vm_named_entry_backing_copy))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_vm_named_entry_size"); Spacer(); Text(hex(UInt64(off_vm_named_entry_size))).foregroundColor(.secondary).monospaced() }
                            
                            HStack { Text("off_label_l_perpolicy_amfi"); Spacer(); Text(hex(UInt64(off_label_l_perpolicy_amfi))).foregroundColor(.secondary).monospaced() }
                            HStack { Text("off_label_l_perpolicy_sandbox"); Spacer(); Text(hex(UInt64(off_label_l_perpolicy_sandbox))).foregroundColor(.secondary).monospaced() }
                            
                            HStack { Text("sizeof_ipc_entry"); Spacer(); Text(hex(UInt64(sizeof_ipc_entry))).foregroundColor(.secondary).monospaced() }
                            
                            HStack { Text("smr_base"); Spacer(); Text(hex(smr_base)).foregroundColor(.secondary).monospaced() }
                            HStack { Text("T1SZ_BOOT"); Spacer(); TextField("0x19", text: t1szbootbind).foregroundColor(.secondary).multilineTextAlignment(.trailing).monospaced() }
                            HStack { Text("VM_MIN_KERNEL_ADDRESS"); Spacer(); Text(hex(VM_MIN_KERNEL_ADDRESS)).foregroundColor(.secondary).monospaced() }
                            HStack { Text("VM_MAX_KERNEL_ADDRESS"); Spacer(); Text(hex(VM_MAX_KERNEL_ADDRESS)).foregroundColor(.secondary).monospaced() }
                        }
                    }
                    Button {
                        save()
                        statusmsg = "偏移量已保存！"
                    } label: {
                        Text("保存偏移量")
                    }
                } header: {
                    Text("偏移量")
                } footer: {
                    Text("修改 t1sz_boot 等值后请手动保存偏移量")
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
                            
                            Text("制作了 darksword-kexploit-fun。")
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
                        AsyncImage(url: URL(string: "https://github.com/khanhduytran0.png")) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading) {
                            Text("Duy Tran")
                                .font(.headline)
                            
                            Text("提供了各种与 remotecall 相关的改进和功能。")
                                .font(.subheadline)
                                .foregroundColor(Color.secondary)
                        }
                        
                        Spacer()
                    }
                    .onTapGesture {
                        if let url = URL(string: "https://github.com/khanhduytran0"),
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
                            
                            Text("帮助我处理偏移量和许多其他事情。没有他，这个项目不可能完成！")
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
                            
                            Text("提供了所有 DirtyZero 调整与情感支持。")
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
                            
                            Text("提供了 EditorView, PocketPoster 助手，以及多项改进。")
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
                            
                            Text("制作了注销脚本。")
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
                    
                    HStack(alignment: .top) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
        
                            Text("汉")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.black)
                        }
    
                        VStack(alignment: .leading) {
                            Text("浮梦往事")
                                .font(.headline)
        
                            Text("完成了汉化工作。\n如有漏翻或翻译不当之处，请务必告知！")
                                .font(.subheadline)
                                .foregroundColor(Color.secondary)
                        }
    
                        Spacer()
                    }
                    .onTapGesture {
                        if let url = URL(string: "https://www.coolapk.com/u/30819340"),
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
        .fileImporter(isPresented: $showkcacheimporter,
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
                            print("failed to import kernelcache: \(error)")
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
        .alert("清除 Kernelcache 数据？", isPresented: $showresetalert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                clearkerncachedata()
            }
        } message: {
            Text("这将删除已下载的 kernelcache 并移除已保存的偏移量。")
        }
        .alert("状态", isPresented: .constant(statusmsg != nil)) {
            Button("确定") { statusmsg = nil }
        } message: {
            Text(statusmsg ?? "")
        }
    }
    
    private func clearkerncachedata() {
        let fm = FileManager.default
        
        UserDefaults.standard.removeObject(forKey: "lara.kernelcache_path")
        UserDefaults.standard.removeObject(forKey: "lara.kernelcache_size")
        
        let docsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let kernelcacheDocPath = docsPath.appendingPathComponent("kernelcache")
        
        do {
            if fm.fileExists(atPath: kernelcacheDocPath.path) {
                try fm.removeItem(at: kernelcacheDocPath)
                mgr.logmsg("Deleted kernelcache from Documents")
            }
        } catch {
            mgr.logmsg("Failed to delete kernelcache: \(error.localizedDescription)")
        }
        
        let tempPath = NSTemporaryDirectory()
        let tempFiles = ["kernelcache.release.ipad", "kernelcache.release.iphone", "kernelcache.release.ipad3", "kernelcache.release.iphone14,3"]
        
        for file in tempFiles {
            let path = tempPath + file
            do {
                if fm.fileExists(atPath: path) {
                    try fm.removeItem(atPath: path)
                    mgr.logmsg("Deleted temp kernelcache: \(file)")
                }
            } catch {
                mgr.logmsg("Failed to delete \(file): \(error.localizedDescription)")
            }
        }
        
        mgr.logmsg("Kernelcache data cleared")
        hasoffsets = false
    }
    
    private func save() {
        UserDefaults.standard.set(t1sz_boot, forKey: "lara.t1sz_boot")
        UserDefaults.standard.synchronize()
        mgr.logmsg("Saved t1sz_boot: 0x\(String(t1sz_boot, radix: 16))")
    }
}

enum method: String, CaseIterable {
    case vfs = "VFS"
    case sbx = "SBX"
    case hybrid = "混合"
}

enum fmAppsDisplayMode: String, CaseIterable {
    case UUID = "UUID"
    case bundleID = "包名 ID"
    case appName = "应用名称"
}
