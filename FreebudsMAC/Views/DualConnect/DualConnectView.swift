// OpenFreebuds/Views/DualConnect/DualConnectView.swift

import SwiftUI
import OFBCore

struct DualConnectDeviceItem: Identifiable {
    var id: String { mac }
    let mac: String
    let name: String
    let connected: Bool
    let playing: Bool
    let preferred: Bool
    let autoConnect: Bool
}

struct DualConnectView: View {
    @ObservedObject var manager: DeviceManager

    @State private var isEnabled: Bool = true
    @State private var preferredDeviceMac: String = ""
    @State private var devices: [DualConnectDeviceItem] = []
    @State private var isRefreshing: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    Text(L10n.tr("tab_dual_connect"))
                        .font(.title3)
                        .fontWeight(.bold)
                    Spacer()

                    Button(action: refreshDeviceList) {
                        HStack(spacing: 4) {
                            if isRefreshing {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text(L10n.tr("refresh"))
                        }
                        .font(.caption)
                    }
                    .disabled(isRefreshing || manager.state != .connected)
                }

                Text(L10n.tr("dual_connect_description"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            ScrollView {
                VStack(spacing: 16) {
                    if manager.state == .disconnected || manager.state == .failed {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L10n.tr("not_connected_title"))
                                    .font(.headline)
                                Text(L10n.tr("not_connected_dual_hint"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.orange.opacity(0.1)))
                    }

                    // 1. Enable Dual Connect Toggle Card
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle(isOn: Binding(
                            get: { isEnabled },
                            set: { newValue in
                                isEnabled = newValue
                                Task {
                                    try? await manager.setProperty(group: "dual_connect", prop: "enabled", value: newValue ? "true" : "false")
                                }
                            }
                        )) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L10n.tr("enable_dual_connect"))
                                    .font(.headline)
                                Text("Allow earbuds to connect to 2 devices simultaneously")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(NSColor.controlBackgroundColor)))

                    // 2. Paired Devices List
                    if isEnabled {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Paired Bluetooth Devices (\(devices.count))")
                                .font(.headline)

                            if devices.isEmpty {
                                HStack {
                                    Spacer()
                                    VStack(spacing: 8) {
                                        Image(systemName: "laptopcomputer.and.iphone")
                                            .font(.largeTitle)
                                            .foregroundColor(.secondary)
                                        Text("No paired dual-connect devices found")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 24)
                                    Spacer()
                                }
                            } else {
                                VStack(spacing: 10) {
                                    ForEach(devices) { dev in
                                        DeviceRowView(
                                            dev: dev,
                                            isPreferred: (dev.mac == preferredDeviceMac),
                                            onToggleConnect: { connect in
                                                toggleDeviceConnect(mac: dev.mac, connect: connect)
                                            },
                                            onSetPreferred: {
                                                setPreferredDevice(mac: dev.mac)
                                            },
                                            onToggleAutoConnect: { auto in
                                                toggleAutoConnect(mac: dev.mac, auto: auto)
                                            },
                                            onUnpair: {
                                                unpairDevice(mac: dev.mac)
                                            }
                                        )
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(NSColor.controlBackgroundColor)))
                    }
                }
                .padding(16)
            }
        }
        .task {
            await refreshData()
            if manager.state == .connected {
                try? await manager.setProperty(group: "dual_connect", prop: "refresh", value: "true")
            }
            let (id, stream) = await manager.eventBus.subscribe()
            for await _ in stream {
                await refreshData()
            }
            await manager.eventBus.unsubscribe(id: id)
        }
    }

    // MARK: - Actions

    private func refreshDeviceList() {
        isRefreshing = true
        Task {
            try? await manager.setProperty(group: "dual_connect", prop: "refresh", value: "true")
            try? await Task.sleep(nanoseconds: 800_000_000)
            await refreshData()
            isRefreshing = false
        }
    }

    private func toggleDeviceConnect(mac: String, connect: Bool) {
        Task {
            try? await manager.setProperty(group: "dual_connect", prop: "\(mac):connected", value: connect ? "true" : "false")
            await refreshData()
        }
    }

    private func setPreferredDevice(mac: String) {
        preferredDeviceMac = mac
        Task {
            try? await manager.setProperty(group: "dual_connect", prop: "preferred_device", value: mac)
            await refreshData()
        }
    }

    private func toggleAutoConnect(mac: String, auto: Bool) {
        Task {
            try? await manager.setProperty(group: "dual_connect", prop: "\(mac):auto_connect", value: auto ? "true" : "false")
            await refreshData()
        }
    }

    private func unpairDevice(mac: String) {
        Task {
            try? await manager.setProperty(group: "dual_connect", prop: "\(mac):unpair", value: "")
            await refreshData()
        }
    }

    private func refreshData() async {
        if let dc = await manager.getProperty(group: "dual_connect", prop: nil, fallback: nil) as? [String: Any] {
            if let enabledStr = dc["enabled"] as? String {
                self.isEnabled = (enabledStr == "true")
            }
            if let pref = dc["preferred_device"] as? String {
                self.preferredDeviceMac = pref
            }

            if let devicesObj = dc["devices"] {
                var map: [String: [String: String]] = [:]
                if let str = devicesObj as? String,
                   let data = str.data(using: .utf8),
                   let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: [String: String]] {
                    map = parsed
                } else if let parsedMap = devicesObj as? [String: [String: String]] {
                    map = parsedMap
                } else if let parsedMap = devicesObj as? [String: Any] {
                    for (mac, val) in parsedMap {
                        if let dict = val as? [String: String] {
                            map[mac] = dict
                        } else if let dict = val as? [String: Any] {
                            var strDict: [String: String] = [:]
                            for (k, v) in dict { strDict[k] = "\(v)" }
                            map[mac] = strDict
                        }
                    }
                }

                var list: [DualConnectDeviceItem] = []
                for (mac, info) in map {
                    let name = info["name"] ?? mac
                    let connected = (info["connected"] == "true")
                    let playing = (info["playing"] == "true")
                    let preferred = (info["preferred"] == "true")
                    let autoConnect = (info["auto_connect"] == "true")

                    list.append(DualConnectDeviceItem(
                        mac: mac,
                        name: name.isEmpty ? mac : name,
                        connected: connected,
                        playing: playing,
                        preferred: preferred,
                        autoConnect: autoConnect
                    ))
                }
                self.devices = list.sorted(by: { a, b in
                    if a.connected != b.connected { return a.connected }
                    return a.name < b.name
                })
            }
        }
    }
}

// MARK: - Device Row Component

struct DeviceRowView: View {
    let dev: DualConnectDeviceItem
    let isPreferred: Bool
    let onToggleConnect: (Bool) -> Void
    let onSetPreferred: () -> Void
    let onToggleAutoConnect: (Bool) -> Void
    let onUnpair: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: deviceIcon(dev.name))
                .font(.title2)
                .foregroundColor(dev.connected ? .blue : .secondary)
                .frame(width: 32)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(dev.name)
                        .font(.system(size: 13, weight: .bold))

                    if dev.playing {
                        Text("🔊 Playing")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.green.opacity(0.2)))
                            .foregroundColor(.green)
                    } else if dev.connected {
                        Text("Connected")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.blue.opacity(0.2)))
                            .foregroundColor(.blue)
                    }
                }

                Text("MAC: \(formatMac(dev.mac))")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Preferred Star Button
            Button(action: onSetPreferred) {
                Image(systemName: isPreferred ? "star.fill" : "star")
                    .foregroundColor(isPreferred ? .yellow : .gray.opacity(0.4))
            }
            .buttonStyle(.plain)
            .help("Set as preferred device")

            // Connect / Disconnect Button
            Button(action: { onToggleConnect(!dev.connected) }) {
                Text(dev.connected ? "Disconnect" : "Connect")
                    .font(.caption)
            }
            .buttonStyle(.bordered)

            // Menu Options (Auto Connect / Unpair)
            Menu {
                Button(action: { onToggleAutoConnect(!dev.autoConnect) }) {
                    Label(dev.autoConnect ? "Disable Auto-Connect" : "Enable Auto-Connect", systemImage: "arrow.triangle.2.circlepath")
                }
                Divider()
                Button(role: .destructive, action: onUnpair) {
                    Label("Unpair Device", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(NSColor.windowBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(dev.connected ? Color.blue.opacity(0.3) : Color.gray.opacity(0.15), lineWidth: 1))
    }

    private func deviceIcon(_ name: String) -> String {
        let n = name.lowercased()
        if n.contains("mac") || n.contains("book") || n.contains("pc") { return "laptopcomputer" }
        if n.contains("phone") || n.contains("iphone") || n.contains("galaxy") { return "iphone" }
        if n.contains("ipad") || n.contains("tablet") { return "ipad" }
        if n.contains("watch") { return "applewatch" }
        if n.contains("tv") { return "tv" }
        return "desktopcomputer"
    }

    private func formatMac(_ raw: String) -> String {
        guard raw.count == 12 else { return raw }
        var res = ""
        for (i, char) in raw.enumerated() {
            if i > 0 && i % 2 == 0 { res += ":" }
            res.append(char)
        }
        return res.uppercased()
    }
}
