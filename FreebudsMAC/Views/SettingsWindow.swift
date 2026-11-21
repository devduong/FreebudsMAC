// OpenFreebuds/Views/SettingsWindow.swift

import SwiftUI
import OFBCore

public enum SettingsTab: Hashable {
    case selectDevice
    case soundQuality
    case gestures
    case dualConnect
    case hotkeys
    case appSettings
    case buyMeCoffee
    case about
}

struct SettingsWindow: View {
    @ObservedObject var manager: DeviceManager
    @ObservedObject var config: AppConfig
    @ObservedObject private var updateChecker = UpdateChecker.shared

    @State private var selectedTab: SettingsTab? = .selectDevice
    @State private var battery: [String: Any] = [:]

    private var preferredScheme: ColorScheme? {
        switch config.appTheme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    private var isDarkAppearance: Bool {
        SettingsWindowManager.shared.isEffectiveDark
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Compact Sidebar Device Status Header
                SidebarDeviceCard(manager: manager, battery: battery)
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
                    .padding(.bottom, 6)

                List(selection: $selectedTab) {
                    Section(L10n.tr("headphones_section")) {
                        NavigationLink(value: SettingsTab.selectDevice) {
                            Label(L10n.tr("tab_overview"), systemImage: "headphones")
                        }
                        NavigationLink(value: SettingsTab.soundQuality) {
                            Label(L10n.tr("tab_sound_quality"), systemImage: "slider.vertical.3")
                        }
                        NavigationLink(value: SettingsTab.gestures) {
                            Label(L10n.tr("tab_gestures"), systemImage: "hand.tap")
                        }
                        NavigationLink(value: SettingsTab.dualConnect) {
                            Label(L10n.tr("tab_dual_connect"), systemImage: "point.3.connected.trianglepath.dotted")
                        }
                    }

                    Section(L10n.tr("application_section")) {
                        NavigationLink(value: SettingsTab.hotkeys) {
                            Label(L10n.tr("tab_hotkeys"), systemImage: "keyboard")
                        }
                        NavigationLink(value: SettingsTab.appSettings) {
                            Label(L10n.tr("tab_settings_unified"), systemImage: "gearshape")
                        }
                        NavigationLink(value: SettingsTab.buyMeCoffee) {
                            Label(L10n.tr("tab_buy_me_coffee"), systemImage: "heart.fill")
                        }
                        NavigationLink(value: SettingsTab.about) {
                            Label(L10n.tr("tab_about"), systemImage: "info.circle")
                        }
                    }
                }
                .listStyle(.sidebar)

                Divider()

                // Quick Appearance Toggle Footer in Sidebar
                HStack(spacing: 8) {
                    Image(systemName: isDarkAppearance ? "moon.stars.fill" : "sun.max.fill")
                        .foregroundColor(isDarkAppearance ? .indigo : .orange)
                        .font(.system(size: 14, weight: .semibold))

                    Text(config.appTheme.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    // Segmented quick pill buttons for Light / Dark / System
                    HStack(spacing: 4) {
                        ThemeIconButton(
                            icon: "sun.max.fill",
                            isActive: config.appTheme == .light || (config.appTheme == .system && !isDarkAppearance),
                            activeColor: .orange,
                            helpText: L10n.tr("theme_light")
                        ) {
                            config.appTheme = .light
                            SettingsWindowManager.shared.applyTheme(.light)
                        }

                        ThemeIconButton(
                            icon: "moon.stars.fill",
                            isActive: config.appTheme == .dark || (config.appTheme == .system && isDarkAppearance),
                            activeColor: .indigo,
                            helpText: L10n.tr("theme_dark")
                        ) {
                            config.appTheme = .dark
                            SettingsWindowManager.shared.applyTheme(.dark)
                        }

                        ThemeIconButton(
                            icon: "circle.lefthalf.filled",
                            isActive: config.appTheme == .system,
                            activeColor: .accentColor,
                            helpText: L10n.tr("theme_system")
                        ) {
                            config.appTheme = .system
                            SettingsWindowManager.shared.applyTheme(.system)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
            .navigationSplitViewColumnWidth(min: 215, ideal: 235, max: 260)
        } detail: {
            Group {
                switch selectedTab {
                case .selectDevice:
                    DeviceSelectionView(manager: manager, config: config)
                case .soundQuality:
                    SoundQualityView(manager: manager)
                case .gestures:
                    GesturesView(manager: manager)
                case .dualConnect:
                    DualConnectView(manager: manager)
                case .hotkeys:
                    HotkeysView(manager: manager)
                case .appSettings:
                    AppSettingsView(config: config)
                case .buyMeCoffee:
                    BuyMeCoffeeView()
                case .about:
                    AboutView()
                case .none:
                    DeviceSelectionView(manager: manager, config: config)
                }
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: {
                        SettingsWindowManager.shared.toggleLightDark(config: config)
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: isDarkAppearance ? "moon.stars.fill" : "sun.max.fill")
                                .foregroundColor(isDarkAppearance ? .indigo : .orange)
                            Text(isDarkAppearance ? L10n.tr("theme_dark") : L10n.tr("theme_light"))
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                    }
                    .help(L10n.tr("theme_toggle_hint"))
                }
            }
        }
        .frame(minWidth: 840, minHeight: 500)
        .preferredColorScheme(preferredScheme)
        .onChange(of: config.appTheme) { newTheme in
            SettingsWindowManager.shared.applyTheme(newTheme)
        }
        .task {
            SettingsWindowManager.shared.applyTheme(config.appTheme)
            await refreshSidebarBattery()
            let (id, stream) = await manager.eventBus.subscribe()
            for await _ in stream {
                await refreshSidebarBattery()
            }
            await manager.eventBus.unsubscribe(id: id)
        }
    }

    private func refreshSidebarBattery() async {
        if manager.state == .connected,
           let bat = await manager.getProperty(group: "battery", prop: nil, fallback: nil) as? [String: Any] {
            self.battery = bat
        } else {
            self.battery = [:]
        }
    }
}

// MARK: - Sidebar Device Status Mini Card

private struct SidebarDeviceCard: View {
    @ObservedObject var manager: DeviceManager
    let battery: [String: Any]

    private var statusColor: Color {
        switch manager.state {
        case .connected: return .green
        case .wait, .paused: return .orange
        case .connectedLimited, .failed: return .yellow
        default: return .secondary
        }
    }

    private var statusLabel: String {
        switch manager.state {
        case .connected: return L10n.tr("state_connected")
        case .wait, .paused: return L10n.tr("state_wait")
        case .connectedLimited: return L10n.tr("state_connected_limited")
        case .failed: return L10n.tr("state_failed")
        default: return L10n.tr("state_disconnected")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)

                Text(manager.deviceName.isEmpty ? AppVersion.appName : manager.deviceName)
                    .font(.system(size: 12, weight: .bold))
                    .lineLimit(1)

                Spacer()
            }

            if manager.state == .connected {
                let left = battery["left"] as? Int
                let right = battery["right"] as? Int
                let caseBat = battery["case"] as? Int
                let global = battery["global"] as? Int

                if left != nil || right != nil || caseBat != nil {
                    HStack(spacing: 8) {
                        if let l = left {
                            MiniBatteryBadge(title: "L", pct: l)
                        }
                        if let r = right {
                            MiniBatteryBadge(title: "R", pct: r)
                        }
                        if let c = caseBat {
                            MiniBatteryBadge(title: "C", pct: c)
                        }
                    }
                } else if let g = global, g > 0 {
                    MiniBatteryBadge(title: "🔋", pct: g)
                } else {
                    Text(statusLabel)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            } else {
                Text(statusLabel)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.75))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct MiniBatteryBadge: View {
    let title: String
    let pct: Int

    var body: some View {
        HStack(spacing: 3) {
            Text(title)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.secondary)
            Text("\(pct)%")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(pct <= 20 ? .red : .primary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Capsule().fill(Color.primary.opacity(0.06)))
    }
}

private struct ThemeIconButton: View {
    let icon: String
    let isActive: Bool
    let activeColor: Color
    let helpText: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(isActive ? activeColor : .secondary)
                .frame(width: 24, height: 22)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isActive ? activeColor.opacity(0.16) : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .help(helpText)
    }
}
