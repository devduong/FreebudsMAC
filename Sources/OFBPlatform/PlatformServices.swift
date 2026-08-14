import Foundation
import AppKit
import CoreBluetooth

public enum PlatformServices {
    /// App storage directory path: ~/Library/Application Support/openfreebuds
    public static var storagePath: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let path = appSupport.appendingPathComponent("openfreebuds", isDirectory: true)
        try? FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
        return path
    }

    /// Check if dark mode is active
    public static var isDarkMode: Bool {
        if let style = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") {
            return style == "Dark"
        }
        return NSApp?.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }

    /// Open file/folder in Finder or default app
    public static func openFile(_ url: URL) {
        NSWorkspace.shared.open(url)
    }

    /// Open System Settings -> Bluetooth
    public static func openBluetoothSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.BluetoothSettings") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Open System Settings -> Accessibility
    public static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Check if system accessibility permission is granted for global hotkeys
    public static var isAccessibilityTrusted: Bool {
        return AXIsProcessTrusted()
    }

    /// Request accessibility permission prompt from macOS
    public static func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options)
        if !trusted {
            openAccessibilitySettings()
        }
    }

    /// Open System Settings -> Notifications
    public static func openNotificationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Check Bluetooth Authorization status
    public static var bluetoothAuthorization: CBManagerAuthorization {
        if #available(macOS 10.15, *) {
            return CBCentralManager.authorization
        }
        return .allowedAlways
    }
}
