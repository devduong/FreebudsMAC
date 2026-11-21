// OpenFreebuds/Views/AppSettings/AppSettingsView.swift

import SwiftUI
import OFBCore
import OFBPlatform
import UserNotifications
import CoreBluetooth

struct AppSettingsView: View {
    @ObservedObject var config: AppConfig
    @ObservedObject private var updateChecker = UpdateChecker.shared

    @State private var runAtBoot: Bool = LaunchAgentManager.isRunAtBoot
    @State private var bluetoothStatus: CBManagerAuthorization = PlatformServices.bluetoothAuthorization
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var accessibilityGranted: Bool = PlatformServices.isAccessibilityTrusted
    @State private var testSent: Bool = false

    private let timer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // MARK: - 1. Appearance, Language & Startup Card
                VStack(alignment: .leading, spacing: 14) {
                    Label(L10n.tr("tab_app_settings"), systemImage: "paintbrush.fill")
                        .font(.headline)

                    Divider()

                    // Theme Row
                    HStack {
                        Text(L10n.tr("theme_title"))
                            .font(.subheadline)
                        Spacer()
                        HStack(spacing: 6) {
                            ForEach(AppTheme.allCases) { theme in
                                Button(action: {
                                    config.appTheme = theme
                                    SettingsWindowManager.shared.applyTheme(theme)
                                }) {
                                    HStack(spacing: 5) {
                                        Image(systemName: theme.iconName)
                                            .font(.caption)
                                        Text(theme.displayName)
                                            .font(.caption)
                                            .fontWeight(config.appTheme == theme ? .semibold : .regular)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(
                                        RoundedRectangle(cornerRadius: 7)
                                            .fill(config.appTheme == theme ? Color.accentColor : Color.primary.opacity(0.07))
                                    )
                                    .foregroundColor(config.appTheme == theme ? .white : .primary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Language Row
                    HStack {
                        Text(L10n.tr("language"))
                            .font(.subheadline)
                        Spacer()
                        Picker("", selection: $config.language) {
                            ForEach(AppLanguage.allCases) { lang in
                                Text(lang.displayName).tag(lang)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(width: 240)
                    }

                    // Launch at Login Row
                    HStack {
                        Text(L10n.tr("launch_at_login"))
                            .font(.subheadline)
                        Spacer()
                        Toggle("", isOn: $runAtBoot)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .onChange(of: runAtBoot) { newValue in
                                try? LaunchAgentManager.setRunAtBoot(newValue)
                            }
                    }

                    // Auto Check Updates Row
                    HStack(spacing: 12) {
                        Text(L10n.tr("auto_check_updates_toggle"))
                            .font(.subheadline)
                        Spacer()
                        Button(action: {
                            Task {
                                await updateChecker.checkForUpdates(isManual: true)
                            }
                        }) {
                            HStack(spacing: 4) {
                                if updateChecker.isChecking {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                }
                                Text(L10n.tr("check_for_updates_btn"))
                            }
                            .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(updateChecker.isChecking)

                        Toggle("", isOn: $config.autoCheckUpdates)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(NSColor.controlBackgroundColor)))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))

                // MARK: - 2. Menu Bar & Low Battery Notifications Card
                VStack(alignment: .leading, spacing: 12) {
                    Label(L10n.tr("tray_options"), systemImage: "menubar.rectangle")
                        .font(.headline)

                    Divider()

                    HStack {
                        Text(L10n.tr("show_battery_in_tray"))
                            .font(.subheadline)
                        Spacer()
                        Toggle("", isOn: $config.showBatteryInTray)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }

                    if config.showBatteryInTray {
                        HStack(spacing: 20) {
                            Toggle(L10n.tr("show_left_battery_in_tray"), isOn: $config.showLeftBatteryInTray)
                            Toggle(L10n.tr("show_right_battery_in_tray"), isOn: $config.showRightBatteryInTray)
                            Toggle(L10n.tr("show_case_battery_in_tray"), isOn: $config.showCaseBatteryInTray)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
                    }

                    HStack {
                        Text(L10n.tr("show_equalizer_in_tray"))
                            .font(.subheadline)
                        Spacer()
                        Toggle("", isOn: $config.trayShowEqualizer)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }

                    HStack {
                        Text(L10n.tr("show_dual_connect_in_tray"))
                            .font(.subheadline)
                        Spacer()
                        Toggle("", isOn: $config.trayShowDualConnect)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }

                    Divider()

                    HStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(L10n.tr("notify_low_battery"))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(L10n.tr("notify_low_battery_hint"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button(action: sendTestNotification) {
                            Label(testSent ? "✓" : L10n.tr("test_notification_btn"), systemImage: "bell.badge")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(!isNotificationAllowed)

                        Toggle("", isOn: $config.notifyLowBattery)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(NSColor.controlBackgroundColor)))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))

                // MARK: - 3. macOS System Permissions Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label(L10n.tr("permissions_section"), systemImage: "lock.shield.fill")
                            .font(.headline)
                        Spacer()
                        Button(action: { refreshPermissions() }) {
                            Label(L10n.tr("perm_refresh_btn"), systemImage: "arrow.clockwise")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }

                    Divider()

                    // Bluetooth
                    PermissionRow(
                        isGranted: isBluetoothAllowed,
                        title: L10n.tr("perm_bluetooth_title"),
                        desc: L10n.tr("perm_bluetooth_desc"),
                        buttonTitle: L10n.tr("perm_btn_open_settings")
                    ) {
                        PlatformServices.openBluetoothSettings()
                    }

                    Divider().opacity(0.5)

                    // Notifications
                    VStack(alignment: .leading, spacing: 6) {
                        PermissionRow(
                            isGranted: isNotificationAllowed,
                            title: L10n.tr("perm_notifications_title"),
                            desc: L10n.tr("perm_notifications_desc"),
                            buttonTitle: notificationStatus == .notDetermined ? L10n.tr("perm_btn_request") : L10n.tr("perm_btn_open_settings")
                        ) {
                            if notificationStatus == .notDetermined {
                                requestNotificationPermission()
                            } else {
                                PlatformServices.openNotificationSettings()
                            }
                        }

                        Text(L10n.tr("perm_notification_banner_tip"))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.leading, 30)
                    }

                    Divider().opacity(0.5)

                    // Accessibility
                    PermissionRow(
                        isGranted: accessibilityGranted,
                        title: L10n.tr("perm_accessibility_title"),
                        desc: L10n.tr("perm_accessibility_desc"),
                        buttonTitle: L10n.tr("perm_btn_grant")
                    ) {
                        PlatformServices.requestAccessibilityPermission()
                    }
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(NSColor.controlBackgroundColor)))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
            }
            .padding(20)
        }
        .onAppear {
            refreshPermissions()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshPermissions()
        }
        .onReceive(timer) { _ in
            refreshPermissions()
        }
    }

    // MARK: - Helpers

    private var isBluetoothAllowed: Bool {
        if #available(macOS 10.15, *) {
            return bluetoothStatus == .allowedAlways
        }
        return true
    }

    private var isNotificationAllowed: Bool {
        return notificationStatus == .authorized || notificationStatus == .provisional
    }

    private func refreshPermissions() {
        accessibilityGranted = PlatformServices.isAccessibilityTrusted
        bluetoothStatus = PlatformServices.bluetoothAuthorization

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationStatus = settings.authorizationStatus
            }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
            DispatchQueue.main.async {
                self.refreshPermissions()
            }
        }
    }

    private func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "\(L10n.tr("low_battery_title")) (FreeBuds)"
        content.body = "\(L10n.tr("low_battery_body", 18)) (\(L10n.tr("test_notification_sent")))"
        content.sound = .default
        if #available(macOS 12.0, *) {
            content.interruptionLevel = .timeSensitive
        }

        let notifId = "test_\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: notifId, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)

        withAnimation { testSent = true }

        Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [notifId])
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            withAnimation { testSent = false }
        }
    }
}

private struct PermissionRow: View {
    let isGranted: Bool
    let title: String
    let desc: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(isGranted ? .green : .orange)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isGranted {
                Text(L10n.tr("perm_status_granted"))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.green.opacity(0.15)))
                    .foregroundColor(.green)
            } else {
                Button(buttonTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
        }
        .padding(.vertical, 2)
    }
}
