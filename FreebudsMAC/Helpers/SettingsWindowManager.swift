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
        // Show app icon in macOS Dock whenever the main window is open
        NSApp.setActivationPolicy(.regular)
        applyTheme(config.appTheme)

        if let window = window {
            if window.isMiniaturized {
                window.deminiaturize(nil)
            }
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsWindow(manager: manager, config: config)
        let hostingController = NSHostingController(rootView: settingsView)

        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 910, height: 560),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        newWindow.title = AppVersion.appName
        newWindow.titlebarAppearsTransparent = false
        newWindow.toolbarStyle = .unified
        newWindow.contentViewController = hostingController
        newWindow.setContentSize(NSSize(width: 910, height: 560))
        newWindow.isReleasedWhenClosed = false
        newWindow.delegate = self

        self.window = newWindow
        applyTheme(config.appTheme)
        centerWindowOnScreen(newWindow)
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Re-center on next layout pass after NSHostingController finishes sizing NavigationSplitView
        DispatchQueue.main.async { [weak self] in
            self?.centerWindowOnScreen(newWindow)
        }
    }

    private func centerWindowOnScreen(_ win: NSWindow) {
        if let screenFrame = (NSScreen.main ?? NSScreen.screens.first)?.visibleFrame {
            let winSize = win.frame.size
            let x = screenFrame.origin.x + (screenFrame.width - winSize.width) / 2.0
            let y = screenFrame.origin.y + (screenFrame.height - winSize.height) / 2.0
            win.setFrameOrigin(NSPoint(x: round(x), y: round(y)))
        } else {
            win.center()
        }
    }

    public func applyTheme(_ theme: AppTheme) {
        let appearance: NSAppearance?
        switch theme {
        case .system:
            appearance = nil
        case .light:
            appearance = NSAppearance(named: .aqua)
        case .dark:
            appearance = NSAppearance(named: .darkAqua)
        }
        NSApp.appearance = appearance
        window?.appearance = appearance
    }

    public var isEffectiveDark: Bool {
        let configTheme = AppConfig.shared.appTheme
        switch configTheme {
        case .dark:
            return true
        case .light:
            return false
        case .system:
            let match = (window?.effectiveAppearance ?? NSApp.effectiveAppearance).bestMatch(from: [.darkAqua, .aqua])
            return match == .darkAqua
        }
    }

    public func toggleLightDark(config: AppConfig) {
        let nextTheme: AppTheme = isEffectiveDark ? .light : .dark
        config.appTheme = nextTheme
        applyTheme(nextTheme)
    }

    public func windowWillClose(_ notification: Notification) {
        window = nil
        // Hide app icon from macOS Dock when user closes the window with "x"
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
