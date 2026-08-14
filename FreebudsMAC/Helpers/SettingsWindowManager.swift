// OpenFreebuds/Helpers/SettingsWindowManager.swift

import SwiftUI
import AppKit
import OFBCore

@MainActor
public final class SettingsWindowManager: NSObject, NSWindowDelegate {
    public static let shared = SettingsWindowManager()

    private var window: NSWindow?

    private override init() {
        super.init()
    }

    public func showWindow(manager: DeviceManager, config: AppConfig) {
        if let window = window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsWindow(manager: manager, config: config)
        let hostingController = NSHostingController(rootView: settingsView)

        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 780, height: 520),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        newWindow.title = "FreebudsMAC Settings"
        newWindow.contentViewController = hostingController
        newWindow.isReleasedWhenClosed = false
        newWindow.delegate = self
        newWindow.center()

        self.window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func windowWillClose(_ notification: Notification) {
        window = nil
    }
}
