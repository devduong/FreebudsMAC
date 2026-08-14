// OpenFreebuds/Views/SettingsWindow.swift

import SwiftUI
import OFBCore

public enum SettingsTab: Hashable {
    case selectDevice
    case deviceInfo
    case soundQuality
    case gestures
    case dualConnect
    case deviceSettings
    case supportedDevices
    case appSettings
    case automation
    case hotkeys
    case macosSettings
    case buyMeCoffee
    case about
}

struct SettingsWindow: View {
    @ObservedObject var manager: DeviceManager
    @ObservedObject var config: AppConfig

    @State private var selectedTab: SettingsTab? = .selectDevice

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                Section(L10n.tr("headphones_section")) {
                    NavigationLink(value: SettingsTab.selectDevice) {
                        Label(L10n.tr("tab_select_device"), systemImage: "antenna.radiowaves.left.and.right")
                    }
                    NavigationLink(value: SettingsTab.deviceInfo) {
                        Label(L10n.tr("tab_device_info"), systemImage: "info.circle")
                    }
                    NavigationLink(value: SettingsTab.soundQuality) {
                        Label(L10n.tr("tab_sound_quality"), systemImage: "speaker.wave.3")
                    }
                    NavigationLink(value: SettingsTab.gestures) {
                        Label(L10n.tr("tab_gestures"), systemImage: "hand.tap")
                    }
                    NavigationLink(value: SettingsTab.dualConnect) {
                        Label(L10n.tr("tab_dual_connect"), systemImage: "link")
                    }
                    NavigationLink(value: SettingsTab.deviceSettings) {
                        Label(L10n.tr("tab_other_settings"), systemImage: "slider.horizontal.3")
                    }
                    NavigationLink(value: SettingsTab.supportedDevices) {
                        Label(L10n.tr("tab_supported_devices"), systemImage: "checkmark.seal")
                    }
                }

                Section(L10n.tr("application_section")) {
                    NavigationLink(value: SettingsTab.appSettings) {
                        Label(L10n.tr("tab_app_settings"), systemImage: "paintbrush")
                    }
                    NavigationLink(value: SettingsTab.automation) {
                        Label(L10n.tr("tab_automation"), systemImage: "gearshape.2")
                    }
                    NavigationLink(value: SettingsTab.hotkeys) {
                        Label(L10n.tr("tab_hotkeys"), systemImage: "keyboard")
                    }
                    NavigationLink(value: SettingsTab.macosSettings) {
                        Label(L10n.tr("tab_macos_settings"), systemImage: "apple.logo")
                    }
                    NavigationLink(value: SettingsTab.buyMeCoffee) {
                        Label(L10n.tr("tab_buy_me_coffee"), systemImage: "heart")
                    }
                    NavigationLink(value: SettingsTab.about) {
                        Label(L10n.tr("tab_about"), systemImage: "info.circle")
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 300)
        } detail: {
            switch selectedTab {
            case .selectDevice:
                DeviceSelectionView(manager: manager, config: config)
            case .deviceInfo:
                DeviceInfoView(manager: manager)
            case .soundQuality:
                SoundQualityView(manager: manager)
            case .gestures:
                GesturesView(manager: manager)
            case .dualConnect:
                DualConnectView(manager: manager)
            case .deviceSettings:
                DeviceSettingsView(manager: manager)
            case .supportedDevices:
                SupportedDevicesView()
            case .appSettings:
                AppSettingsView(config: config)
            case .automation:
                AutomationView(manager: manager, config: config)
            case .hotkeys:
                HotkeysView(manager: manager)
            case .macosSettings:
                MacOSSettingsView()
            case .buyMeCoffee:
                BuyMeCoffeeView()
            case .about:
                AboutView()
            case .none:
                Text("Select an option from the sidebar.")
            }
        }
        .frame(minWidth: 720, minHeight: 480)
    }
}
