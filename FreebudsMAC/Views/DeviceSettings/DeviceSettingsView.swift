// OpenFreebuds/Views/DeviceSettings/DeviceSettingsView.swift

import SwiftUI
import OFBCore

struct DeviceSettingsView: View {
    @ObservedObject var manager: DeviceManager

    @State private var lowLatency: Bool = false
    @State private var autoPause: Bool = true

    var body: some View {
        Form {
            if manager.state == .disconnected || manager.state == .failed {
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

            Section(L10n.tr("audio_latency")) {
                Toggle(L10n.tr("low_latency_mode"), isOn: Binding(
                    get: { lowLatency },
                    set: { newValue in
                        lowLatency = newValue
                        Task {
                            try? await manager.setProperty(group: "config", prop: "low_latency", value: newValue ? "true" : "false")
                        }
                    }
                ))

                Toggle(L10n.tr("auto_pause"), isOn: Binding(
                    get: { autoPause },
                    set: { newValue in
                        autoPause = newValue
                        Task {
                            try? await manager.setProperty(group: "config", prop: "auto_pause", value: newValue ? "true" : "false")
                        }
                    }
                ))
            }
        }
        .padding()
        .task {
            await refreshData()
            let (id, stream) = await manager.eventBus.subscribe()
            for await _ in stream {
                await refreshData()
            }
            await manager.eventBus.unsubscribe(id: id)
        }
    }

    private func refreshData() async {
        if let config = await manager.getProperty(group: "config", prop: nil, fallback: nil) as? [String: String] {
            if let ll = config["low_latency"] { self.lowLatency = (ll == "true") }
            if let ap = config["auto_pause"] { self.autoPause = (ap == "true") }
        }
    }
}
