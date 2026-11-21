// OpenFreebuds/Views/DeviceSelection/DeviceSelectionView.swift

import SwiftUI
import OFBCore
import OFBBluetooth

struct DeviceSelectionView: View {
    @ObservedObject var manager: DeviceManager
    @ObservedObject var config: AppConfig

    @State private var pairedDevices: [PairedDevice] = []
    @State private var isLoading = false

    // Live device state
    @State private var info: [String: String] = [:]
    @State private var battery: [String: Any] = [:]
    @State private var stateInfo: [String: String] = [:]
    @State private var ancMode: String = "normal"
    @State private var ancLevel: String = "normal"
    @State private var ancLevelOptions: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 1. Hero Device Status & Battery Card
                deviceHeroCard

                // 2. Quick Noise Control (ANC) Card when connected
                if manager.state == .connected {
                    quickANCCard
                }

                // 3. Bluetooth Device Selector Card
                deviceSelectorCard

                // 4. Compact Technical Info Card (Firmware, Serial, MAC)
                if !manager.deviceName.isEmpty {
                    technicalDetailsCard
                }
            }
            .padding(20)
        }
        .task {
            await loadDevices()
            await refreshDashboard()
            let (id, stream) = await manager.eventBus.subscribe()
            for await _ in stream {
                await refreshDashboard()
            }
            await manager.eventBus.unsubscribe(id: id)
        }
    }

    // MARK: - 1. Hero Device Status & Battery Card

    private var deviceHeroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(manager.state == .connected ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: "headphones")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(manager.state == .connected ? .accentColor : .secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(manager.deviceName.isEmpty ? L10n.tr("select_device") : manager.deviceName)
                        .font(.title3)
                        .fontWeight(.bold)

                    HStack(spacing: 8) {
                        StatusDotBadge(state: manager.state, text: stateDescription(manager.state))

                        if manager.state == .connected {
                            let inEarProp = stateInfo["in_ear"]
                            let hasEarbudsActive = (battery["left"] != nil || battery["right"] != nil)
                            let isWearing = (inEarProp == "true") || (inEarProp == nil && hasEarbudsActive)
                            Text(isWearing ? "👂 \(L10n.tr("in_ear"))" : L10n.tr("out_of_ear"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                // Connection Action Button
                if manager.state == .connected {
                    Button(L10n.tr("menu_disconnect")) {
                        Task {
                            try? await manager.shortcuts.execute(.disconnect)
                            await refreshDashboard()
                        }
                    }
                    .buttonStyle(.bordered)
                } else if manager.state == .connectedLimited || manager.state == .failed {
                    Button(L10n.tr("retry")) {
                        Task { await manager.retryConnection() }
                    }
                    .buttonStyle(.borderedProminent)
                } else if !manager.deviceAddress.isEmpty {
                    Button(L10n.tr("menu_connect")) {
                        Task {
                            try? await manager.shortcuts.execute(.connect)
                            await refreshDashboard()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            if manager.state == .connectedLimited || manager.state == .failed {
                Text(L10n.tr("connected_limited_hint"))
                    .font(.caption)
                    .foregroundColor(.orange)
            }

            // Battery Grid when connected
            if manager.state == .connected {
                let left = battery["left"] as? Int
                let right = battery["right"] as? Int
                let caseBat = battery["case"] as? Int
                let global = battery["global"] as? Int
                let isCharging = (battery["is_charging"] as? String) == "true"

                if left != nil || right != nil || caseBat != nil {
                    Divider()
                    HStack(spacing: 12) {
                        if let l = left {
                            BatteryCardItem(icon: "l.circle.fill", title: L10n.tr("left_headphone"), percentage: l)
                        }
                        if let r = right {
                            BatteryCardItem(icon: "r.circle.fill", title: L10n.tr("right_headphone"), percentage: r)
                        }
                        if let c = caseBat {
                            BatteryCardItem(icon: "shippingbox.fill", title: L10n.tr("charging_case"), percentage: c)
                        }
                    }
                } else if let g = global, g > 0 {
                    Divider()
                    BatteryCardItem(
                        icon: isCharging ? "bolt.batteryblock.fill" : "battery.100",
                        title: isCharging ? "\(L10n.tr("battery")) (\(L10n.tr("charging")))" : L10n.tr("battery"),
                        percentage: g
                    )
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(NSColor.controlBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
    }

    // MARK: - 2. Quick Noise Control (ANC) Card

    private var quickANCCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.tr("menu_noise_control"))
                .font(.headline)

            HStack(spacing: 10) {
                ANCModePill(
                    icon: "speaker.wave.2.fill",
                    title: L10n.tr("menu_anc_off"),
                    isSelected: ancMode == "normal" || ancMode == "off"
                ) {
                    setANC("normal")
                }

                ANCModePill(
                    icon: "shield.lefthalf.filled",
                    title: L10n.tr("menu_anc_on"),
                    isSelected: ancMode == "cancellation" || ancMode == "anc"
                ) {
                    setANC("cancellation")
                }

                ANCModePill(
                    icon: "ear.and.waveform",
                    title: L10n.tr("menu_anc_awareness"),
                    isSelected: ancMode == "awareness"
                ) {
                    setANC("awareness")
                }
            }

            let levelOpts = ancLevelOptions.split(separator: ",").map(String.init).filter { !$0.isEmpty }
            if (ancMode == "cancellation" || ancMode == "anc" || ancMode == "awareness") && !levelOpts.isEmpty {
                HStack(spacing: 8) {
                    Text(ancMode == "awareness" ? L10n.tr("anc_awareness_level_title") : L10n.tr("anc_levels_title"))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    ForEach(levelOpts, id: \.self) { opt in
                        Button(action: { setANCLevel(opt) }) {
                            Text(ancLevelDisplayName(opt))
                                .font(.caption)
                                .fontWeight(ancLevel == opt ? .semibold : .regular)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule().fill(ancLevel == opt ? Color.accentColor : Color.primary.opacity(0.07))
                                )
                                .foregroundColor(ancLevel == opt ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(NSColor.controlBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
    }

    // MARK: - 3. Paired Bluetooth Devices Card

    private var deviceSelectorCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L10n.tr("select_device"))
                    .font(.headline)

                Spacer()

                Toggle(L10n.tr("auto_select"), isOn: $config.autoSetup)
                    .toggleStyle(.switch)
                    .controlSize(.small)

                Button(action: { Task { await loadDevices() } }) {
                    Label(L10n.tr("refresh_devices"), systemImage: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(isLoading)
            }

            if !config.autoSetup {
                Text(L10n.tr("manual_select_hint"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            if isLoading {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text(L10n.tr("scanning_devices"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            } else if pairedDevices.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.tr("no_devices_found"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(L10n.tr("no_devices_hint"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 6)
            } else {
                VStack(spacing: 8) {
                    ForEach(pairedDevices) { device in
                        let isSupported = DeviceRegistry.isSupported(device.name)
                        let canSelect = isSupported || !config.autoSetup
                        let isCurrent = (manager.deviceAddress == device.address)

                        HStack(spacing: 12) {
                            Image(systemName: isSupported ? "headphones" : "dot.radiowaves.left.and.right")
                                .foregroundColor(isCurrent ? .accentColor : .secondary)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(device.name)
                                    .font(.system(size: 13, weight: .semibold))
                                Text(device.address)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if device.isConnected {
                                Text(L10n.tr("macos_connected"))
                                    .font(.system(size: 10, weight: .medium))
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.green.opacity(0.18)))
                                    .foregroundColor(.green)
                            }

                            if !isSupported {
                                Text(L10n.tr("unlisted_generic_tag"))
                                    .font(.system(size: 10, weight: .medium))
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.orange.opacity(0.15)))
                                    .foregroundColor(.orange)
                            }

                            if canSelect {
                                Button(isCurrent ? L10n.tr("selected") : L10n.tr("select")) {
                                    selectDevice(name: device.name, address: device.address)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .disabled(isCurrent)
                            } else {
                                Text(L10n.tr("unsupported"))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isCurrent ? Color.accentColor.opacity(0.08) : Color(NSColor.windowBackgroundColor).opacity(0.5))
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(NSColor.controlBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
    }

    // MARK: - 4. Compact Technical Info Card

    private var technicalDetailsCard: some View {
        HStack(spacing: 24) {
            InfoPillItem(label: L10n.tr("mac_address"), value: manager.deviceAddress.isEmpty ? L10n.tr("none") : manager.deviceAddress)
            Divider().frame(height: 26)
            InfoPillItem(label: L10n.tr("firmware_version"), value: info["firmware_version"] ?? L10n.tr("unknown"))
            Divider().frame(height: 26)
            InfoPillItem(label: L10n.tr("serial_number"), value: info["serial_number"] ?? L10n.tr("unknown"))
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(NSColor.controlBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
    }

    // MARK: - Actions & Helpers

    private func selectDevice(name: String, address: String) {
        config.setDeviceData(name: name, address: address)
        Task {
            try? await manager.start(deviceName: name, deviceAddress: address)
            await refreshDashboard()
        }
    }

    private func loadDevices() async {
        isLoading = true
        let list = await BluetoothManager.shared.listPairedDevices()
        // Sort connected and supported devices first
        pairedDevices = list.sorted { a, b in
            if a.isConnected != b.isConnected { return a.isConnected }
            let aSup = DeviceRegistry.isSupported(a.name)
            let bSup = DeviceRegistry.isSupported(b.name)
            if aSup != bSup { return aSup }
            return a.name < b.name
        }
        isLoading = false
    }

    private func setANC(_ mode: String) {
        ancMode = mode
        Task {
            try? await manager.setProperty(group: "anc", prop: "mode", value: mode)
            await refreshDashboard()
        }
    }

    private func setANCLevel(_ level: String) {
        ancLevel = level
        Task {
            try? await manager.setProperty(group: "anc", prop: "level", value: level)
            await refreshDashboard()
        }
    }

    private func ancLevelDisplayName(_ level: String) -> String {
        switch level {
        case "comfort": return L10n.tr("anc_lvl_comfort")
        case "normal": return L10n.tr("anc_lvl_normal")
        case "ultra": return L10n.tr("anc_lvl_ultra")
        case "dynamic": return L10n.tr("anc_lvl_dynamic")
        case "voice_boost": return L10n.tr("anc_lvl_voice_boost")
        default: return level.capitalized
        }
    }

    private func stateDescription(_ state: DeviceState) -> String {
        switch state {
        case .stopped: return L10n.tr("state_stopped")
        case .disconnected: return L10n.tr("state_disconnected")
        case .wait, .paused: return L10n.tr("state_wait")
        case .connected: return L10n.tr("state_connected")
        case .failed: return L10n.tr("state_failed")
        case .destroyed: return L10n.tr("state_destroyed")
        case .connectedLimited: return L10n.tr("state_connected_limited")
        }
    }

    private func refreshDashboard() async {
        if let infoData = await manager.getProperty(group: "info", prop: nil, fallback: nil) as? [String: String] {
            self.info = infoData
        }
        if let batteryData = await manager.getProperty(group: "battery", prop: nil, fallback: nil) as? [String: Any] {
            self.battery = batteryData
        }
        if let stateData = await manager.getProperty(group: "state", prop: nil, fallback: nil) as? [String: String] {
            self.stateInfo = stateData
        }
        if let anc = await manager.getProperty(group: "anc", prop: nil, fallback: nil) as? [String: String] {
            self.ancMode = anc["mode"] ?? "normal"
            self.ancLevel = anc["level"] ?? "normal"
            self.ancLevelOptions = anc["level_options"] ?? ""
        }
    }
}

// MARK: - Subcomponents

private struct StatusDotBadge: View {
    let state: DeviceState
    let text: String

    private var color: Color {
        switch state {
        case .connected: return .green
        case .wait, .paused: return .orange
        case .connectedLimited, .failed: return .yellow
        default: return .secondary
        }
    }

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color == .secondary ? .secondary : color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Capsule().fill(color.opacity(0.14)))
    }
}

private struct BatteryCardItem: View {
    let icon: String
    let title: String
    let percentage: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 4)
                Text("\(percentage)%")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(percentage <= 20 ? .red : .primary)
                    .fixedSize()
            }
            ProgressView(value: Double(max(0, min(100, percentage))), total: 100)
                .tint(percentage <= 20 ? .red : .green)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 56, maxHeight: 56)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.windowBackgroundColor).opacity(0.6)))
    }
}

private struct ANCModePill: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor : Color(NSColor.windowBackgroundColor).opacity(0.6))
            )
            .foregroundColor(isSelected ? .white : .primary)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.clear : Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct InfoPillItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .textSelection(.enabled)
        }
    }
}
