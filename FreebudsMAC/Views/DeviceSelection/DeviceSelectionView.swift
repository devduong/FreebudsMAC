// OpenFreebuds/Views/DeviceSelection/DeviceSelectionView.swift

import SwiftUI
import OFBCore
import OFBBluetooth

struct DeviceSelectionView: View {
    @ObservedObject var manager: DeviceManager
    @ObservedObject var config: AppConfig

    @State private var pairedDevices: [PairedDevice] = []
    @State private var isLoading = false

    var body: some View {
        Form {
            Section {
                Toggle(L10n.tr("auto_select"), isOn: $config.autoSetup)

                if !config.autoSetup {
                    Text(L10n.tr("manual_select_hint"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text(L10n.tr("auto_setup"))
            }

            Section(L10n.tr("select_device")) {
                if isLoading {
                    ProgressView(L10n.tr("scanning_devices"))
                } else if pairedDevices.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.tr("no_devices_found"))
                            .fontWeight(.medium)
                        Text(L10n.tr("no_devices_hint"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    ForEach(pairedDevices) { device in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(device.name)
                                    .font(.headline)
                                Text(device.address)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            let isSupported = DeviceRegistry.isSupported(device.name)
                            let canSelect = isSupported || !config.autoSetup

                            HStack(spacing: 8) {
                                if device.isConnected {
                                    Text(L10n.tr("macos_connected"))
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.green.opacity(0.2))
                                        .foregroundColor(.green)
                                        .cornerRadius(4)
                                }

                                if !isSupported {
                                    Text(L10n.tr("unlisted_generic_tag"))
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.orange.opacity(0.15))
                                        .foregroundColor(.orange)
                                        .cornerRadius(4)
                                }

                                if canSelect {
                                    Button(manager.deviceAddress == device.address ? L10n.tr("selected") : L10n.tr("select")) {
                                        selectDevice(name: device.name, address: device.address)
                                    }
                                    .disabled(manager.deviceAddress == device.address)
                                } else {
                                    Text(L10n.tr("unsupported"))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }

                Button(L10n.tr("refresh_devices")) {
                    Task { await loadDevices() }
                }
            }
        }
        .padding()
        .task {
            await loadDevices()
        }
    }

    private func selectDevice(name: String, address: String) {
        config.setDeviceData(name: name, address: address)
        Task {
            try? await manager.start(deviceName: name, deviceAddress: address)
        }
    }

    private func loadDevices() async {
        isLoading = true
        pairedDevices = await BluetoothManager.shared.listPairedDevices()
        isLoading = false
    }
}
