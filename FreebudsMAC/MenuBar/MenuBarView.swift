// OpenFreebuds/MenuBar/MenuBarView.swift

import SwiftUI
import OFBCore
import OFBPlatform

struct MenuBarView: View {
    @ObservedObject var manager: DeviceManager
    @ObservedObject var config: AppConfig

    @State private var batteryInfo: [String: Any]? = nil
    @State private var ancMode: String = "normal"
    @State private var ancLevel: String = "normal"
    @State private var ancLevelOptions: String = ""
    @State private var eqPreset: String = ""
    @State private var eqPresetOptions: [String] = []
    @State private var dualConnectEnabled: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: Device Name
            if !manager.deviceName.isEmpty {
                Text(manager.deviceName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("FreebudsMAC")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Connection actions
            if manager.state == .disconnected || manager.state == .stopped {
                Button(L10n.tr("menu_connect")) {
                    Task {
                        try? await manager.shortcuts.execute(.connect)
                        await refreshMenuData()
                    }
                }
            } else {
                Button(L10n.tr("menu_disconnect")) {
                    Task {
                        try? await manager.shortcuts.execute(.disconnect)
                        await refreshMenuData()
                    }
                }
            }

            Divider()

            // Battery Section
            if manager.state == .connected {
                if let battery = batteryInfo {
                    let hasLeft = battery["left"] != nil
                    let hasRight = battery["right"] != nil
                    let hasCase = battery["case"] != nil
                    let global = (battery["global"] as? Int) ?? 0

                    if hasLeft || hasRight || hasCase {
                        if let left = battery["left"] as? Int {
                            Text("\(L10n.tr("menu_left")): \(left)%")
                                .foregroundColor(.secondary)
                        }
                        if let right = battery["right"] as? Int {
                            Text("\(L10n.tr("menu_right")): \(right)%")
                                .foregroundColor(.secondary)
                        }
                        if let caseBattery = battery["case"] as? Int {
                            Text("\(L10n.tr("menu_case")): \(caseBattery)%")
                                .foregroundColor(.secondary)
                        }
                    } else if global > 0 {
                        let chargingText = (battery["is_charging"] as? String == "true") ? " ⚡" : ""
                        Text("\(L10n.tr("menu_battery")): \(global)%\(chargingText)")
                            .foregroundColor(.secondary)
                    } else {
                        Text(L10n.tr("menu_reading_battery"))
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text(L10n.tr("menu_reading_battery"))
                        .foregroundColor(.secondary)
                }

                Divider()

                // Noise Control Direct Radio Buttons (Matching original PyQt design)
                Button(action: { setANC("normal") }) {
                    HStack {
                        Image(systemName: (ancMode == "normal" || ancMode == "off") ? "checkmark.square.fill" : "square")
                        Text(L10n.tr("menu_anc_off"))
                    }
                }

                Button(action: { setANC("cancellation") }) {
                    HStack {
                        Image(systemName: (ancMode == "cancellation" || ancMode == "anc") ? "checkmark.square.fill" : "square")
                        Text(L10n.tr("menu_anc_on"))
                    }
                }

                Button(action: { setANC("awareness") }) {
                    HStack {
                        Image(systemName: (ancMode == "awareness") ? "checkmark.square.fill" : "square")
                        Text(L10n.tr("menu_anc_awareness"))
                    }
                }

                // ANC Level Submenu if available for cancellation / awareness
                if (ancMode == "cancellation" || ancMode == "anc") && !ancLevelOptions.isEmpty {
                    Menu("  ↳ " + L10n.tr("anc_levels_title")) {
                        let options = ancLevelOptions.components(separatedBy: ",")
                        ForEach(options, id: \.self) { opt in
                            Button(action: { setANCLevel(opt) }) {
                                HStack {
                                    Text(ancLevelDisplayName(opt))
                                    if ancLevel == opt { Image(systemName: "checkmark") }
                                }
                            }
                        }
                    }
                }

                if ancMode == "awareness" && !ancLevelOptions.isEmpty {
                    Menu("  ↳ " + L10n.tr("anc_awareness_level_title")) {
                        let options = ancLevelOptions.components(separatedBy: ",")
                        ForEach(options, id: \.self) { opt in
                            Button(action: { setANCLevel(opt) }) {
                                HStack {
                                    Text(ancLevelDisplayName(opt))
                                    if ancLevel == opt { Image(systemName: "checkmark") }
                                }
                            }
                        }
                    }
                }

                // Equalizer Submenu (conditional)
                if config.trayShowEqualizer && !eqPresetOptions.isEmpty {
                    Divider()
                    Menu(L10n.tr("menu_equalizer")) {
                        ForEach(eqPresetOptions, id: \.self) { preset in
                            Button(action: { setEQPreset(preset) }) {
                                HStack {
                                    Text(formatPresetName(preset))
                                    if eqPreset == preset { Image(systemName: "checkmark") }
                                }
                            }
                        }
                    }
                }

                // Dual Connect Submenu (conditional)
                if config.trayShowDualConnect {
                    Divider()
                    Menu(L10n.tr("menu_dual_connect")) {
                        Toggle(L10n.tr("menu_dual_connect_enabled"), isOn: Binding(
                            get: { dualConnectEnabled },
                            set: { newValue in
                                dualConnectEnabled = newValue
                                Task {
                                    try? await manager.setProperty(group: "dual_connect", prop: "enabled", value: newValue ? "true" : "false")
                                }
                            }
                        ))
                    }
                }

                Divider()
            }

            // Settings...
            Button(L10n.tr("menu_settings")) {
                SettingsWindowManager.shared.showWindow(manager: manager, config: config)
            }
            .keyboardShortcut(",")

            Divider()

            // Bugreport...
            Button(L10n.tr("menu_bugreport")) {
                if let url = URL(string: "https://github.com/devduong") {
                    NSWorkspace.shared.open(url)
                }
            }

            // Leave application
            Button(L10n.tr("menu_quit")) {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .task {
            await refreshMenuData()
            await manager.requestBatteryUpdate()
            let (id, stream) = await manager.eventBus.subscribe()
            for await _ in stream {
                await refreshMenuData()
            }
            await manager.eventBus.unsubscribe(id: id)
        }
    }

    // MARK: - Actions

    private func setANC(_ mode: String) {
        ancMode = mode
        Task {
            try? await manager.setProperty(group: "anc", prop: "mode", value: mode)
            await refreshMenuData()
        }
    }

    private func setANCLevel(_ level: String) {
        ancLevel = level
        Task {
            try? await manager.setProperty(group: "anc", prop: "level", value: level)
            await refreshMenuData()
        }
    }

    private func setEQPreset(_ preset: String) {
        eqPreset = preset
        Task {
            try? await manager.setProperty(group: "sound", prop: "equalizer_preset", value: preset)
        }
    }

    private func formatPresetName(_ name: String) -> String {
        name.replacingOccurrences(of: "equalizer_preset_", with: "").capitalized
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

    // MARK: - Data Refresh

    private func refreshMenuData() async {
        if manager.state == .connected {
            let battery = await manager.getProperty(group: "battery", prop: nil, fallback: nil) as? [String: Any]
            self.batteryInfo = battery

            if let anc = await manager.getProperty(group: "anc", prop: nil, fallback: nil) as? [String: String] {
                self.ancMode = anc["mode"] ?? "normal"
                self.ancLevel = anc["level"] ?? "normal"
                self.ancLevelOptions = anc["level_options"] ?? ""
            }

            if let sound = await manager.getProperty(group: "sound", prop: nil, fallback: nil) as? [String: String] {
                self.eqPreset = sound["equalizer_preset"] ?? ""
                if let options = sound["equalizer_preset_options"] {
                    self.eqPresetOptions = options.components(separatedBy: ",")
                }
            }

            if let dc = await manager.getProperty(group: "dual_connect", prop: nil, fallback: nil) as? [String: String] {
                self.dualConnectEnabled = (dc["enabled"] == "true")
            }
        }
    }
}
