// OFBCore/Constants.swift

import Foundation

public enum OfbEventKind {
    public static let stateChanged       = "state_changed"
    public static let deviceChanged      = "device_changed"
    public static let propertyChanged    = "prop_changed"
    public static let bringSettingsUp    = "qt::show_settings"
    public static let settingsChanged    = "qt::settings_changed"
}

public enum DeviceState: Int, Sendable, CustomStringConvertible {
    case destroyed         = -1
    case stopped           = 0
    case disconnected      = 1
    case wait              = 2
    case connected         = 3
    case failed            = 4
    case paused            = 5
    case connectedLimited  = 6   // Bluetooth connected, RFCOMM unavailable

    public var description: String {
        switch self {
        case .destroyed: return "Destroyed"
        case .stopped: return "Stopped"
        case .disconnected: return "Disconnected"
        case .wait: return "Waiting"
        case .connected: return "Connected"
        case .failed: return "Failed"
        case .paused: return "Paused"
        case .connectedLimited: return "Connected (Limited)"
        }
    }
}

