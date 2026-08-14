// OpenFreebuds/Views/MacOSSettings/MacOSSettingsView.swift

import SwiftUI
import OFBPlatform
import OFBCore
import UserNotifications
import CoreBluetooth

struct MacOSSettingsView: View {
    @State private var runAtBoot: Bool = LaunchAgentManager.isRunAtBoot
    @State private var statusMessage: String = ""

    // Permission states
    @State private var bluetoothStatus: CBManagerAuthorization = PlatformServices.bluetoothAuthorization
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var accessibilityGranted: Bool = PlatformServices.isAccessibilityTrusted
    @State private var testSent: Bool = false

    private let timer = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()

    var body: some View {
        Form {
            // MARK: - macOS Integration
            Section(L10n.tr("macos_integration_title")) {
                Toggle(L10n.tr("launch_at_login"), isOn: $runAtBoot)
                    .onChange(of: runAtBoot) { newValue in
                        do {
                            try LaunchAgentManager.setRunAtBoot(newValue)
                            statusMessage = newValue ? L10n.tr("launchagent_enabled") : L10n.tr("launchagent_disabled")
                        } catch {
                            statusMessage = "Failed to update LaunchAgent: \(error.localizedDescription)"
                        }
                    }

                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // MARK: - 3 System Permissions (Each in its own clean row)
            Section(L10n.tr("permissions_section")) {
                // 1. Bluetooth Permission Row
                HStack(spacing: 12) {
                    Image(systemName: isBluetoothAllowed ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundColor(isBluetoothAllowed ? .green : .orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.tr("perm_bluetooth_title"))
                            .font(.body)
                            .fontWeight(.medium)
                        Text(L10n.tr("perm_bluetooth_desc"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if isBluetoothAllowed {
                        StatusBadge(title: L10n.tr("perm_status_granted"), isGreen: true)
                    } else {
                        Button(L10n.tr("open_bluetooth_settings")) {
                            PlatformServices.openBluetoothSettings()
                        }
                        .controlSize(.small)
                    }
                }
                .padding(.vertical, 4)

                // 2. Notification Permission Row
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 12) {
                        Image(systemName: isNotificationAllowed ? "checkmark.circle.fill" : (notificationStatus == .denied ? "xmark.circle.fill" : "exclamationmark.circle.fill"))
                            .font(.title2)
                            .foregroundColor(isNotificationAllowed ? .green : (notificationStatus == .denied ? .red : .orange))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.tr("perm_notifications_title"))
                                .font(.body)
                                .fontWeight(.medium)
                            Text(L10n.tr("perm_notifications_desc"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if isNotificationAllowed {
                            StatusBadge(title: L10n.tr("perm_status_granted"), isGreen: true)
                        } else if notificationStatus == .notDetermined {
                            Button(L10n.tr("perm_btn_request")) {
                                requestNotificationPermission()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        } else {
                            Button(L10n.tr("perm_btn_open_settings")) {
                                PlatformServices.openNotificationSettings()
                            }
                            .controlSize(.small)
                        }
                    }

                    // Tip to enable Banners in System Settings
                    Text(L10n.tr("perm_notification_banner_tip"))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.leading, 36)
                }
                .padding(.vertical, 4)

                // 3. Accessibility Permission Row
                HStack(spacing: 12) {
                    Image(systemName: accessibilityGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(accessibilityGranted ? .green : .red)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.tr("perm_accessibility_title"))
                            .font(.body)
                            .fontWeight(.medium)
                        Text(L10n.tr("perm_accessibility_desc"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if accessibilityGranted {
                        StatusBadge(title: L10n.tr("perm_status_granted"), isGreen: true)
                    } else {
                        Button(L10n.tr("perm_btn_grant")) {
                            PlatformServices.requestAccessibilityPermission()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
                .padding(.vertical, 4)

                // Test Notification Action
                HStack(spacing: 12) {
                    Button(action: sendTestNotification) {
                        Label(L10n.tr("test_notification_btn"), systemImage: "bell.badge")
                    }
                    .disabled(!isNotificationAllowed)

                    Button(action: { refreshPermissions() }) {
                        Label(L10n.tr("perm_refresh_btn"), systemImage: "arrow.clockwise")
                    }
                    .controlSize(.small)

                    if testSent {
                        Text(L10n.tr("test_notification_sent"))
                            .font(.caption)
                            .foregroundColor(.green)
                            .transition(.opacity)
                    }
                }
                .padding(.top, 4)
            }

            // MARK: - Quick Links
            Section(L10n.tr("quick_links_title")) {
                Button(L10n.tr("open_bluetooth_settings")) {
                    PlatformServices.openBluetoothSettings()
                }

                Button(L10n.tr("open_accessibility_settings")) {
                    PlatformServices.openAccessibilitySettings()
                }

                Button(L10n.tr("open_notification_settings")) {
                    PlatformServices.openNotificationSettings()
                }
            }
        }
        .padding()
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
        content.title = "🔋 FreeBuds Low Battery"
        content.body = "Battery at 18%. (Test Notification - Auto hide in 3s)"
        content.sound = .default
        if #available(macOS 12.0, *) {
            content.interruptionLevel = .timeSensitive
        }

        let notifId = "test_\(UUID().uuidString)"
        let request = UNNotificationRequest(
            identifier: notifId,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)

        withAnimation { testSent = true }

        // Auto dismiss / hide notification banner after 3 seconds
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [notifId])
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation { testSent = false }
        }
    }
}

// MARK: - Status Badge Component
private struct StatusBadge: View {
    let title: String
    let isGreen: Bool

    var body: some View {
        Text(title)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(isGreen ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
            .foregroundColor(isGreen ? .green : .red)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isGreen ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
            )
    }
}

