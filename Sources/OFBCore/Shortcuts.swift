// OFBCore/Shortcuts.swift

import Foundation
import OFBBluetooth

public enum ShortcutAction: String, CaseIterable, Sendable {
    case modeNormal          = "mode_normal"
    case modeCancellation    = "mode_cancellation"
    case modeAwareness       = "mode_awareness"
    case enableLowLatency    = "enable_low_latency"
    case nextMode            = "next_mode"
    case toggleConnect       = "toggle_connect"
    case connect             = "connect"
    case disconnect          = "disconnect"
}

public actor Shortcuts {
    private weak var manager: DeviceManager?

    public init(manager: DeviceManager?) {
        self.manager = manager
    }

    public func execute(_ action: ShortcutAction) async throws {
        guard let manager = manager else { return }

        switch action {
        case .modeNormal:
            try await manager.setProperty(group: "anc", prop: "mode", value: "normal")
        case .modeCancellation:
            try await manager.setProperty(group: "anc", prop: "mode", value: "cancellation")
        case .modeAwareness:
            try await manager.setProperty(group: "anc", prop: "mode", value: "awareness")
        case .enableLowLatency:
            try await manager.setProperty(group: "config", prop: "low_latency", value: "true")
        case .nextMode:
            if let anc = await manager.getProperty(group: "anc", prop: nil, fallback: nil) as? [String: String],
               let mode = anc["mode"],
               let optionsStr = anc["mode_options"] {
                let options = optionsStr.components(separatedBy: ",")
                if let idx = options.firstIndex(of: mode) {
                    let nextIdx = (idx + 1) % options.count
                    let nextMode = options[nextIdx]
                    try await manager.setProperty(group: "anc", prop: "mode", value: nextMode)
                }
            }
        case .toggleConnect:
            let state = await manager.state
            if state == .connected {
                try await execute(.disconnect)
            } else {
                try await execute(.connect)
            }
        case .connect:
            let addr = await manager.deviceAddress
            _ = await BluetoothManager.shared.connect(address: addr)
        case .disconnect:
            let addr = await manager.deviceAddress
            _ = await BluetoothManager.shared.disconnect(address: addr)
        }
    }
}
