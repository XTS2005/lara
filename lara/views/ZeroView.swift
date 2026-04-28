//
//  ZeroView.swift
//  lara
//
//  Created by ruter on 28.03.26.
//

import SwiftUI

struct tweak: Identifiable {
    let id: String
    let name: String
    let path: [String]

    init(name: String, path: [String]) {
        self.name = name
        self.path = path
        self.id = name + "|" + path.joined(separator: "|")
    }
}

struct ZeroView: View {
    @ObservedObject var mgr: laramgr
    @AppStorage("selecteddata") private var selecteddata: Data = Data()
    @State private var selected: Set<String> = []

    let tweaks: [tweak] = [
        tweak(name: "隐藏 Dock 栏背景", path: ["/System/Library/PrivateFrameworks/CoreMaterial.framework/dockDark.materialrecipe", "/System/Library/PrivateFrameworks/CoreMaterial.framework/dockLight.materialrecipe"]),
        tweak(name: "清除文件夹背景", path: ["/System/Library/PrivateFrameworks/SpringBoardHome.framework/folderDark.materialrecipe", "/System/Library/PrivateFrameworks/SpringBoardHome.framework/folderLight.materialrecipe"]),
        tweak(name: "清除小组件配置背景", path: ["/System/Library/PrivateFrameworks/SpringBoardHome.framework/stackConfigurationBackground.materialrecipe", "/System/Library/PrivateFrameworks/SpringBoardHome.framework/stackConfigurationForeground.materialrecipe"]),
        tweak(name: "清除 App 资源库背景", path: ["/System/Library/PrivateFrameworks/SpringBoardHome.framework/coplanarLeadingTrailingBackgroundBlur.materialrecipe"]),
        tweak(name: "清除资源库搜索背景", path: ["/System/Library/PrivateFrameworks/SpringBoardHome.framework/homeScreenOverlay.materialrecipe"]),
        tweak(name: "清除 Spotlight 背景", path: ["/System/Library/PrivateFrameworks/SpringBoardHome.framework/knowledgeBackgroundDarkZoomed.descendantrecipe", "/System/Library/PrivateFrameworks/SpringBoardHome.framework/knowledgeBackgroundZoomed.descendantrecipe"]),
        tweak(name: "隐藏删除图标", path: ["/System/Library/PrivateFrameworks/SpringBoardHome.framework/Assets.car"]),
        tweak(name: "清除密码背景", path: ["/System/Library/PrivateFrameworks/CoverSheet.framework/dashBoardPasscodeBackground.materialrecipe"]),
        tweak(name: "隐藏锁屏图标", path: ["/System/Library/PrivateFrameworks/SpringBoardUIServices.framework/lock@2x-812h.ca/main.caml", "/System/Library/PrivateFrameworks/SpringBoardUIServices.framework/lock@2x-896h.ca/main.caml", "/System/Library/PrivateFrameworks/SpringBoardUIServices.framework/lock@3x-812h.ca/main.caml", "/System/Library/PrivateFrameworks/SpringBoardUIServices.framework/lock@3x-896h.ca/main.caml", "/System/Library/PrivateFrameworks/SpringBoardUIServices.framework/lock@3x-d73.ca/main.caml"]),
        tweak(name: "隐藏快捷操作图标", path: ["/System/Library/PrivateFrameworks/CoverSheet.framework/Assets.car"]),
        tweak(name: "隐藏大电池图标", path: ["/System/Library/PrivateFrameworks/CoverSheet.framework/Assets.car"]),
        tweak(name: "清除通知与小组件背景", path: ["/System/Library/PrivateFrameworks/CoreMaterial.framework/platterStrokeLight.visualstyleset", "/System/Library/PrivateFrameworks/CoreMaterial.framework/platterStrokeDark.visualstyleset", "/System/Library/PrivateFrameworks/CoreMaterial.framework/plattersDark.materialrecipe", "/System/Library/PrivateFrameworks/CoreMaterial.framework/platters.materialrecipe", "/System/Library/PrivateFrameworks/UserNotificationsUIKit.framework/stackDimmingLight.visualstyleset", "/System/Library/PrivateFrameworks/UserNotificationsUIKit.framework/stackDimmingDark.visualstyleset"]),
        tweak(name: "蓝色通知阴影", path: ["/System/Library/PrivateFrameworks/PlatterKit.framework/platterVibrantShadowLight.visualstyleset", "/System/Library/PrivateFrameworks/PlatterKit.framework/platterVibrantShadowDark.visualstyleset"]),
        tweak(name: "清除触控与弹窗背景", path: ["/System/Library/PrivateFrameworks/CoreMaterial.framework/platformContentDark.materialrecipe", "/System/Library/PrivateFrameworks/CoreMaterial.framework/platformContentLight.materialrecipe"]),
        tweak(name: "隐藏主屏幕横条", path: ["/System/Library/PrivateFrameworks/MaterialKit.framework/Assets.car"]),
        tweak(name: "移除毛玻璃覆盖层", path: ["/System/Library/PrivateFrameworks/CoreMaterial.framework/platformChromeDark.materialrecipe", "/System/Library/PrivateFrameworks/CoreMaterial.framework/platformChromeLight.materialrecipe"]),
        tweak(name: "清除应用切换器背景", path: ["/System/Library/PrivateFrameworks/SpringBoard.framework/homeScreenBackdrop-application.materialrecipe", "/System/Library/PrivateFrameworks/SpringBoard.framework/homeScreenBackdrop-switcher.materialrecipe"]),
        tweak(name: "启用 Helvetica 字体", path: ["/System/Library/Fonts/Core/SFUI.ttf"]),
        tweak(name: "启用 Helvetica 字体 ", path: ["/System/Library/Fonts/CoreUI/SFUI.ttf"]),
        tweak(name: "禁用表情符号", path: ["/System/Library/Fonts/CoreAddition/AppleColorEmoji-160px.ttc"]),
        tweak(name: "隐藏响铃图标", path: ["/System/Library/PrivateFrameworks/SpringBoard.framework/Ringer-Leading-D73.ca/main.caml"]),
        tweak(name: "隐藏热点图标", path: ["/System/Library/PrivateFrameworks/SpringBoard.framework/Tethering-D73.ca/main.caml"]),
        tweak(name: "清除控制中心模块背景", path: ["/System/Library/PrivateFrameworks/CoreMaterial.framework/modulesSheer.descendantrecipe", "/System/Library/ControlCenter/Bundles/FocusUIModule.bundle/Info.plist"]),
        tweak(name: "禁用滑块图标 ", path: ["/System/Library/ControlCenter/Bundles/DisplayModule.bundle/Brightness.ca/index.xml", "/System/Library/PrivateFrameworks/MediaControls.framework/Volume.ca/index.xml"]),
        tweak(name: "禁用滑块图标", path: ["/System/Library/ControlCenter/Bundles/DisplayModule.bundle/Brightness.ca/index.xml", "/System/Library/PrivateFrameworks/MediaControls.framework/VolumeSemibold.ca/index.xml"]),
        tweak(name: "隐藏播放器按钮", path: ["/System/Library/PrivateFrameworks/MediaControls.framework/PlayPauseStop.ca/index.xml", "/System/Library/PrivateFrameworks/MediaControls.framework/ForwardBackward.ca/index.xml"]),
        tweak(name: "隐藏勿扰图标", path: ["/System/Library/PrivateFrameworks/FocusUI.framework/dnd_cg_02.ca/main.caml"]),
        tweak(name: "隐藏 WiFi 与蓝牙图标", path: ["/System/Library/ControlCenter/Bundles/ConnectivityModule.bundle/Bluetooth.ca/index.xml", "/System/Library/ControlCenter/Bundles/ConnectivityModule.bundle/WiFi.ca/index.xml"]),
        tweak(name: "禁用屏幕镜像模块", path: ["/System/Library/ControlCenter/Bundles/AirPlayMirroringModule.bundle/Info.plist"]),
        tweak(name: "禁用方向锁定模块", path: ["/System/Library/ControlCenter/Bundles/OrientationLockModule.bundle/Info.plist"]),
        tweak(name: "禁用专注模块", path: ["/System/Library/ControlCenter/Bundles/FocusUIModule.bundle/Info.plist"]),
        tweak(name: "禁用隔空投送提示音", path: ["/System/Library/Audio/UISounds/Modern/airdrop_invite.cat"]),
        tweak(name: "禁用充电声音", path: ["/System/Library/Audio/UISounds/connect_power.caf"]),
        tweak(name: "禁用低电量声音", path: ["/System/Library/Audio/UISounds/low_power.caf"]),
        tweak(name: "禁用支付声音", path: ["/System/Library/Audio/UISounds/payment_success.caf", "/System/Library/Audio/UISounds/payment_failure.caf"]),
        tweak(name: "禁用拨号声音", path: ["/System/Library/Audio/UISounds/nano/dtmf-0.caf", "/System/Library/Audio/UISounds/nano/dtmf-1.caf", "/System/Library/Audio/UISounds/nano/dtmf-2.caf", "/System/Library/Audio/UISounds/nano/dtmf-3.caf", "/System/Library/Audio/UISounds/nano/dtmf-4.caf", "/System/Library/Audio/UISounds/nano/dtmf-5.caf", "/System/Library/Audio/UISounds/nano/dtmf-6.caf", "/System/Library/Audio/UISounds/nano/dtmf-7.caf", "/System/Library/Audio/UISounds/nano/dtmf-8.caf", "/System/Library/Audio/UISounds/nano/dtmf-9.caf", "/System/Library/Audio/UISounds/nano/dtmf-pound.caf", "/System/Library/Audio/UISounds/nano/dtmf-star.caf"]),
        tweak(name: "移除控制中心背景", path: ["/System/Library/PrivateFrameworks/CoreMaterial.framework/modulesBackground.materialrecipe"]),
        tweak(name: "禁用所有横幅通知", path: ["/System/Library/PrivateFrameworks/SpringBoard.framework/BannersAuthorizedBundleIDs.plist"]),
        tweak(name: "禁用所有强调色", path: ["/System/Library/PrivateFrameworks/CoreUI.framework/DesignLibrary-iOS.bundle/iOSRepositories/DarkStandard.car"]),
        tweak(name: "分隔系统字体", path: ["/System/Library/Fonts/Core/SFUI.ttf", "/System/Library/Fonts/Core/Helvetica.ttc"]),
        tweak(name: "分隔时钟字体", path: ["/System/Library/Fonts/Core/ADTNumeric.ttc"]),
        tweak(name: "分隔主屏幕标签", path: ["/System/Library/PrivateFrameworks/SpringBoardUIServices.framework/SpringBoardUIServices.loctable", "/System/Library/PrivateFrameworks/SpringBoardHome.framework/SpringBoardHome.loctable", "/System/Library/CoreServices/SpringBoard.app/SpringBoard.loctable"]),
        tweak(name: "分隔设置标签", path: ["/System/Library/PrivateFrameworks/Settings/SoundsAndHapticsSettings.framework/Sounds.loctable", "/System/Library/PrivateFrameworks/Settings/DisplayAndBrightnessSettings.framework/ColorSchedule.loctable", "/System/Library/PrivateFrameworks/Settings/DisplayAndBrightnessSettings.framework/ColorTemperature.loctable", "/System/Library/PrivateFrameworks/Settings/DisplayAndBrightnessSettings.framework/DeviceAppearanceSchedule.loctable", "/System/Library/PrivateFrameworks/Settings/DisplayAndBrightnessSettings.framework/Display.loctable", "/System/Library/PrivateFrameworks/Settings/DisplayAndBrightnessSettings.framework/ExternalDisplays.loctable", "/System/Library/PrivateFrameworks/Settings/DisplayAndBrightnessSettings.framework/FineTune.loctable", "/System/Library/PrivateFrameworks/Settings/DisplayAndBrightnessSettings.framework/LargeFontsSettings.loctable", "/System/Library/PrivateFrameworks/Settings/DisplayAndBrightnessSettings.framework/Magnify.loctable", "/System/Library/PrivateFrameworks/Settings/GeneralSettingsUI.framework/About.loctable", "/System/Library/PrivateFrameworks/Settings/GeneralSettingsUI.framework/AutomaticContentDownload.loctable", "/System/Library/PrivateFrameworks/Settings/GeneralSettingsUI.framework/BackupAlert.loctable", "/System/Library/PrivateFrameworks/Settings/GeneralSettingsUI.framework/BackupInfo.loctable", "/System/Library/PrivateFrameworks/Settings/GeneralSettingsUI.framework/Date & Time.loctable", "/System/Library/PrivateFrameworks/Settings/GeneralSettingsUI.framework/General.loctable", "/System/Library/PrivateFrameworks/Settings/GeneralSettingsUI.framework/HomeButton-sshb.loctable", "/System/Library/PrivateFrameworks/Settings/GeneralSettingsUI.framework/Localizable.loctable", "/System/Library/PrivateFrameworks/Settings/GeneralSettingsUI.framework/LOTX.loctable", "/System/Library/PrivateFrameworks/Settings/GeneralSettingsUI.framework/Matter.loctable", "/System/Library/PrivateFrameworks/Settings/GeneralSettingsUI.framework/ModelNames.loctable", "/System/Library/PrivateFrameworks/Settings/GeneralSettingsUI.framework/Nfc.loctable", "/System/Library/PrivateFrameworks/Settings/GeneralSettingsUI.framework/Nfc.loctable", "/System/Library/PrivateFrameworks/Settings/GeneralSettingsUI.framework/Pointers.loctable", "/System/Library/PrivateFrameworks/Settings/GeneralSettingsUI.framework/Reset-Simulator.loctable", "/System/Library/PrivateFrameworks/Settings/GeneralSettingsUI.framework/Reset.loctable", "/System/Library/PrivateFrameworks/Settings/PrivacySettingsUI.framework/Privacy.loctable", "/System/Library/PrivateFrameworks/Settings/PrivacySettingsUI.framework/Almanac-ALMANAC.loctable", "/System/Library/PrivateFrameworks/Settings/PrivacySettingsUI.framework/AppleAdvertising.loctable", "/System/Library/PrivateFrameworks/Settings/PrivacySettingsUI.framework/AppReport.loctable", "/System/Library/PrivateFrameworks/Settings/PrivacySettingsUI.framework/Dim-Sum.loctable", "/System/Library/PrivateFrameworks/Settings/PrivacySettingsUI.framework/Localizable.loctable", "/System/Library/PrivateFrameworks/Settings/PrivacySettingsUI.framework/Location Services.loctable", "/System/Library/PrivateFrameworks/Settings/PrivacySettingsUI.framework/LocationServicesPrivacy.loctable", "/System/Library/PrivateFrameworks/Settings/PrivacySettingsUI.framework/LockdownMode.loctable", "/System/Library/PrivateFrameworks/Settings/PrivacySettingsUI.framework/Privacy.loctable", "/System/Library/PrivateFrameworks/Settings/PrivacySettingsUI.framework/Restrictions.loctable", "/System/Library/PrivateFrameworks/Settings/PrivacySettingsUI.framework/Safety.loctable", "/System/Library/PrivateFrameworks/Settings/PrivacySettingsUI.framework/Trackers.loctable", "System/Library/PrivateFrameworks/SettingsFoundation.framework/CountryOfOriginAssembledIn.loctable"])
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(tweaks) { tweak in
                        HStack {
                            Text(tweak.name)
                            Spacer()
                            Image(systemName: selected.contains(tweak.id) ? "circle.fill" : "circle")
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            select(tweak: tweak)
                        }
                    }
                } footer: {
                    Text("特别感谢 [jailbreak.party](https://github.com/jailbreakdotparty/dirtyZero)！\n注意：许多调整目前无法使用。这可能会在未来的更新中修复。")
                }
            }
            .navigationTitle("DirtyZero")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("应用") {
                        apply()
                    }
                }
            }
            .onAppear {
                if let decoded = try? JSONDecoder().decode([String].self, from: selecteddata) {
                    selected = Set(decoded)
                }
            }
        }
    }
    
    func select(tweak: tweak) {
        if selected.contains(tweak.id) {
            selected.remove(tweak.id)
        } else {
            selected.insert(tweak.id)
        }
        
        selecteddata = (try? JSONEncoder().encode(Array(selected))) ?? Data()
    }

    func apply() {
        for tweak in tweaks where selected.contains(tweak.id) {
            for path in tweak.path {
                mgr.vfszeropage(at: path)
            }
        }
    }
}
