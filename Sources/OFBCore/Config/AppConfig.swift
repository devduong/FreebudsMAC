// OFBCore/Config/AppConfig.swift

import Foundation
import Combine

@MainActor
public final class AppConfig: ObservableObject {
    public static let shared = AppConfig()

    private let defaults = UserDefaults.standard

    // MARK: - Published Properties

    @Published public var language: AppLanguage {
        didSet {
            defaults.set(language.rawValue, forKey: "language")
            L10n.currentLanguage = language
        }
    }

    @Published public var showBatteryInTray: Bool {
        didSet { defaults.set(showBatteryInTray, forKey: "show_battery_in_tray") }
    }

    @Published public var showLeftBatteryInTray: Bool {
        didSet { defaults.set(showLeftBatteryInTray, forKey: "show_left_battery_in_tray") }
    }

    @Published public var showRightBatteryInTray: Bool {
        didSet { defaults.set(showRightBatteryInTray, forKey: "show_right_battery_in_tray") }
    }

    @Published public var showCaseBatteryInTray: Bool {
        didSet { defaults.set(showCaseBatteryInTray, forKey: "show_case_battery_in_tray") }
    }

    @Published public var deviceName: String {
        didSet { defaults.set(deviceName, forKey: "device_name") }
    }

    @Published public var deviceAddress: String {
        didSet { defaults.set(deviceAddress, forKey: "device_address") }
    }

    @Published public var autoSetup: Bool {
        didSet { defaults.set(autoSetup, forKey: "auto_setup") }
    }

    @Published public var runInBackground: Bool {
        didSet { defaults.set(runInBackground, forKey: "run_in_background") }
    }

    @Published public var trayShowEqualizer: Bool {
        didSet { defaults.set(trayShowEqualizer, forKey: "tray_show_equalizer") }
    }

    @Published public var trayShowDualConnect: Bool {
        didSet { defaults.set(trayShowDualConnect, forKey: "tray_show_dual_connect") }
    }

    @Published public var notifyLowBattery: Bool {
        didSet { defaults.set(notifyLowBattery, forKey: "notify_low_battery") }
    }

    private init() {
        let langRaw = defaults.string(forKey: "language") ?? "system"
        let lang = AppLanguage(rawValue: langRaw) ?? .system
        self.language = lang
        L10n.currentLanguage = lang

        self.showBatteryInTray = defaults.object(forKey: "show_battery_in_tray") == nil ? true : defaults.bool(forKey: "show_battery_in_tray")
        self.showLeftBatteryInTray = defaults.object(forKey: "show_left_battery_in_tray") == nil ? true : defaults.bool(forKey: "show_left_battery_in_tray")
        self.showRightBatteryInTray = defaults.object(forKey: "show_right_battery_in_tray") == nil ? true : defaults.bool(forKey: "show_right_battery_in_tray")
        self.showCaseBatteryInTray = defaults.object(forKey: "show_case_battery_in_tray") == nil ? true : defaults.bool(forKey: "show_case_battery_in_tray")
        self.deviceName = defaults.string(forKey: "device_name") ?? ""
        self.deviceAddress = defaults.string(forKey: "device_address") ?? ""
        self.autoSetup = defaults.object(forKey: "auto_setup") == nil ? true : defaults.bool(forKey: "auto_setup")
        self.runInBackground = defaults.object(forKey: "run_in_background") == nil ? true : defaults.bool(forKey: "run_in_background")
        self.trayShowEqualizer = defaults.bool(forKey: "tray_show_equalizer")
        self.trayShowDualConnect = defaults.bool(forKey: "tray_show_dual_connect")
        self.notifyLowBattery = defaults.object(forKey: "notify_low_battery") == nil ? true : defaults.bool(forKey: "notify_low_battery")
    }

    public func setDeviceData(name: String, address: String) {
        self.deviceName = name
        self.deviceAddress = address
    }
}
