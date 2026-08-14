// OpenFreebuds/Views/DeviceInfo/DeviceInfoView.swift

import SwiftUI
import OFBCore

struct DeviceInfoView: View {
    @ObservedObject var manager: DeviceManager

    @State private var info: [String: String] = [:]
    @State private var battery: [String: Any] = [:]
    @State private var stateInfo: [String: String] = [:]

    var body: some View {
        Form {
            if manager.state == .disconnected {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.tr("not_connected_title"))
                                .font(.headline)
                            Text(L10n.tr("not_connected_hint"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } else if manager.state == .connectedLimited || manager.state == .failed {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "wifi.exclamationmark")
                            .foregroundColor(.yellow)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.tr("connected_limited_title"))
                                .font(.headline)
                            Text(L10n.tr("connected_limited_hint"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button(L10n.tr("retry")) {
                            Task { await manager.retryConnection() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.vertical, 4)
                }
            } else if manager.state == .wait {
                Section {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text(L10n.tr("state_wait"))
                            .font(.headline)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section(L10n.tr("device_overview")) {
                LabeledContent(L10n.tr("device_model"), value: manager.deviceName.isEmpty ? L10n.tr("none") : manager.deviceName)
                LabeledContent(L10n.tr("mac_address"), value: manager.deviceAddress.isEmpty ? L10n.tr("none") : manager.deviceAddress)
                LabeledContent(L10n.tr("status"), value: stateDescription(manager.state))
                LabeledContent(L10n.tr("firmware_version"), value: info["firmware_version"] ?? L10n.tr("unknown"))
                LabeledContent(L10n.tr("serial_number"), value: info["serial_number"] ?? L10n.tr("unknown"))
            }

            if manager.state == .connected {
                Section(L10n.tr("battery_status")) {
                    let hasLeft = battery["left"] != nil
                    let hasRight = battery["right"] != nil
                    let hasCase = battery["case"] != nil

                    if let left = battery["left"] as? Int {
                        BatteryRow(label: L10n.tr("left_headphone"), percentage: left)
                    }
                    if let right = battery["right"] as? Int {
                        BatteryRow(label: L10n.tr("right_headphone"), percentage: right)
                    }
                    if let caseBattery = battery["case"] as? Int {
                        BatteryRow(label: L10n.tr("charging_case"), percentage: caseBattery)
                    }
                    if !hasLeft && !hasRight && !hasCase, let global = battery["global"] as? Int {
                        BatteryRow(label: L10n.tr("battery"), percentage: global)
                    }
                    if let isCharging = battery["is_charging"] as? String {
                        LabeledContent(L10n.tr("charging_status"), value: isCharging == "true" ? L10n.tr("charging") : L10n.tr("not_charging"))
                    }
                }

                Section(L10n.tr("wear_detection")) {
                    let inEarProp = stateInfo["in_ear"]
                    let hasEarbudsActive = (battery["left"] != nil || battery["right"] != nil)
                    let isWearing = (inEarProp == "true") || (inEarProp == nil && hasEarbudsActive)

                    LabeledContent(L10n.tr("wear_status"), value: isWearing ? L10n.tr("in_ear") : L10n.tr("out_of_ear"))
                }
            }
        }
        .padding()
        .task {
            await refreshInfo()
            let (id, stream) = await manager.eventBus.subscribe()
            for await _ in stream {
                await refreshInfo()
            }
            await manager.eventBus.unsubscribe(id: id)
        }
    }

    private func stateDescription(_ state: DeviceState) -> String {
        switch state {
        case .stopped: return L10n.tr("state_stopped")
        case .disconnected: return L10n.tr("state_disconnected")
        case .wait: return L10n.tr("state_wait")
        case .connected: return L10n.tr("state_connected")
        case .failed: return L10n.tr("state_failed")
        case .destroyed: return L10n.tr("state_destroyed")
        case .paused: return L10n.tr("state_wait")
        case .connectedLimited: return L10n.tr("state_connected_limited")
        }
    }

    private func refreshInfo() async {
        if let infoData = await manager.getProperty(group: "info", prop: nil, fallback: nil) as? [String: String] {
            self.info = infoData
        }
        if let batteryData = await manager.getProperty(group: "battery", prop: nil, fallback: nil) as? [String: Any] {
            self.battery = batteryData
        }
        if let stateData = await manager.getProperty(group: "state", prop: nil, fallback: nil) as? [String: String] {
            self.stateInfo = stateData
        }
    }
}

struct BatteryRow: View {
    let label: String
    let percentage: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                Spacer()
                Text("\(percentage)%")
                    .foregroundColor(.secondary)
            }
            ProgressView(value: Double(percentage), total: 100)
                .tint(percentage > 20 ? .green : .red)
        }
    }
}
