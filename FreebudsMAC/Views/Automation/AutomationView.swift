// OpenFreebuds/Views/Automation/AutomationView.swift

import SwiftUI
import OFBCore

struct AutomationView: View {
    @ObservedObject var manager: DeviceManager
    @ObservedObject var config: AppConfig

    @State private var autoPause: Bool = true

    var body: some View {
        Form {
            Section(L10n.tr("automation_title")) {
                Toggle(L10n.tr("auto_pause_media"), isOn: Binding(
                    get: { autoPause },
                    set: { newValue in
                        autoPause = newValue
                        Task {
                            try? await manager.setProperty(group: "config", prop: "auto_pause", value: newValue ? "true" : "false")
                        }
                    }
                ))

                Toggle(L10n.tr("auto_connect_on_launch"), isOn: $config.autoSetup)
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
        if let cfg = await manager.getProperty(group: "config", prop: nil, fallback: nil) as? [String: String] {
            if let ap = cfg["auto_pause"] { self.autoPause = (ap == "true") }
        }
    }
}
