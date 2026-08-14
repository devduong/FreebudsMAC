// OpenFreebuds/Views/Hotkeys/HotkeysView.swift

import SwiftUI
import OFBCore
import OFBPlatform

struct HotkeyItem: Identifiable {
    let id = UUID()
    let icon: String
    let titleKey: String
    let fallbackTitle: String
    let keys: [String]
    let action: ShortcutAction
}

struct HotkeysView: View {
    @ObservedObject var manager: DeviceManager
    @State private var isAccessibilityTrusted: Bool = PlatformServices.isAccessibilityTrusted
    @State private var executingAction: ShortcutAction? = nil

    private let hotkeys: [HotkeyItem] = [
        HotkeyItem(icon: "arrow.triangle.2.circlepath", titleKey: "hotkey_cycle_anc", fallbackTitle: "Cycle Noise Control Mode (ANC)", keys: ["⌥", "⌘", "A"], action: .nextMode),
        HotkeyItem(icon: "power", titleKey: "hotkey_toggle_connect", fallbackTitle: "Toggle Connect / Disconnect", keys: ["⌥", "⌘", "C"], action: .toggleConnect),
        HotkeyItem(icon: "speaker.wave.2", titleKey: "menu_anc_off", fallbackTitle: "Disable Noise Control (Normal)", keys: ["⌥", "⌘", "0"], action: .modeNormal),
        HotkeyItem(icon: "shield.fill", titleKey: "menu_anc_on", fallbackTitle: "Noise Cancellation (ANC)", keys: ["⌥", "⌘", "1"], action: .modeCancellation),
        HotkeyItem(icon: "ear", titleKey: "menu_anc_awareness", fallbackTitle: "Awareness Mode", keys: ["⌥", "⌘", "2"], action: .modeAwareness),
        HotkeyItem(icon: "gamecontroller.fill", titleKey: "config_low_latency", fallbackTitle: "Low Latency Gaming Mode", keys: ["⌥", "⌘", "L"], action: .enableLowLatency)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Banner Card
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 52, height: 52)
                        Image(systemName: "keyboard.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.tr("global_hotkeys_title"))
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(L10n.tr("hotkeys_subtitle"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
                .cornerRadius(12)

                // Accessibility Permission Banner
                HStack(spacing: 14) {
                    Image(systemName: isAccessibilityTrusted ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundColor(isAccessibilityTrusted ? .green : .orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(isAccessibilityTrusted ? L10n.tr("accessibility_active") : L10n.tr("permissions_required_title"))
                            .fontWeight(.semibold)
                        Text(isAccessibilityTrusted ? L10n.tr("accessibility_active_desc") : L10n.tr("accessibility_permission_hint"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button(L10n.tr("open_accessibility_settings")) {
                        PlatformServices.openAccessibilitySettings()
                        refreshPermissionStatus()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(isAccessibilityTrusted ? .accentColor : .orange)
                }
                .padding()
                .background(isAccessibilityTrusted ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isAccessibilityTrusted ? Color.green.opacity(0.3) : Color.orange.opacity(0.3), lineWidth: 1)
                )

                // Shortcuts List Card
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.tr("active_shortcuts_section"))
                        .font(.headline)
                        .foregroundColor(.secondary)

                    VStack(spacing: 1) {
                        ForEach(hotkeys) { item in
                            HStack(spacing: 12) {
                                Image(systemName: item.icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(.accentColor)
                                    .frame(width: 24)

                                Text(L10n.tr(item.titleKey))
                                    .font(.body)
                                    .fontWeight(.medium)

                                Spacer()

                                // Keycaps badge representation
                                HStack(spacing: 4) {
                                    ForEach(item.keys, id: \.self) { key in
                                        KeyCapView(keyText: key)
                                    }
                                }

                                // Quick test button
                                Button(action: {
                                    triggerShortcut(item.action)
                                }) {
                                    if executingAction == item.action {
                                        ProgressView()
                                            .controlSize(.small)
                                    } else {
                                        Text(L10n.tr("test_shortcut"))
                                            .font(.caption)
                                    }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .disabled(manager.state != .connected && item.action != .toggleConnect)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .background(Color(NSColor.controlBackgroundColor))
                        }
                    }
                    .cornerRadius(8)
                }
            }
            .padding(20)
        }
        .onAppear {
            refreshPermissionStatus()
        }
    }

    private func refreshPermissionStatus() {
        isAccessibilityTrusted = PlatformServices.isAccessibilityTrusted
    }

    private func triggerShortcut(_ action: ShortcutAction) {
        executingAction = action
        Task {
            try? await manager.shortcuts.execute(action)
            try? await Task.sleep(nanoseconds: 300_000_000)
            await MainActor.run {
                executingAction = nil
            }
        }
    }
}

/// Visual KeyCap component matching macOS native aesthetic
struct KeyCapView: View {
    let keyText: String

    var body: some View {
        Text(keyText)
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .foregroundColor(.primary)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color(NSColor.windowBackgroundColor))
                    .shadow(color: Color.black.opacity(0.15), radius: 1, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )
    }
}
