// FreebudsMAC/FreebudsMACApp.swift

import SwiftUI
import Combine
import OFBCore
import OFBPlatform
import OFBBluetooth
import UserNotifications

@main
struct FreebudsMACApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // macOS Menu Bar Extra (tray icon)
        MenuBarExtra {
            MenuBarView(manager: appDelegate.manager, config: appDelegate.config)
        } label: {
            MenuBarLabelView(appDelegate: appDelegate)
        }

        // Settings Window
        Settings {
            SettingsWindow(manager: appDelegate.manager, config: appDelegate.config)
        }
    }
}

struct MenuBarLabelView: View {
    @ObservedObject var appDelegate: AppDelegate
    @ObservedObject var config = AppConfig.shared

    var body: some View {
        if config.showBatteryInTray,
           appDelegate.manager.state == .connected,
           let text = appDelegate.batteryText,
           !text.isEmpty {
            (Text(Image(systemName: "headphones")) + Text("  \(text)"))
        } else {
            Image(systemName: "headphones")
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate, ObservableObject {
    let manager = DeviceManager()
    let config = AppConfig.shared
    private let rpcServer = RPCServer()

    @Published var batteryPercentage: Int? = nil
    @Published var batteryText: String? = nil
    private var doubleClickMonitor: Any?
    private var cancellables = Set<AnyCancellable>()
    private var didNotify20: Bool = false
    private var didNotify10: Bool = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
        UNUserNotificationCenter.current().delegate = self

        setupDoubleClickHandler()
        setupConfigObservers()

        Task { @MainActor in
            await autoStartDevice()
            try? await rpcServer.start(manager: manager)
            GlobalHotkeyManager.shared.setup(manager: manager)
            requestNotificationPermission()

            // Open Settings Window on manual launch, but keep silent (tray icon only) when autostarting on login
            if !isAutostart {
                SettingsWindowManager.shared.showWindow(manager: manager, config: config)
            }

            setupBatteryMonitoring()
        }
    }

    private var isAutostart: Bool {
        let args = ProcessInfo.processInfo.arguments
        return args.contains("--autostart") || args.contains("--onlogin") || args.contains("-autostart") || args.contains("-onlogin") || args.contains("autostart") || args.contains("onlogin")
    }

    private func setupConfigObservers() {
        config.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.updateBatteryInfo()
                }
            }
            .store(in: &cancellables)
    }

    private func setupDoubleClickHandler() {
        doubleClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] event in
            guard let self = self else { return event }
            let winClass = event.window?.className ?? ""
            if winClass.contains("StatusBar") || winClass.contains("StatusItem") {
                if event.clickCount == 2 {
                    Task { @MainActor in
                        try? await self.manager.shortcuts.execute(.nextMode)
                    }
                }
            }
            return event
        }
    }

    // MARK: - Battery Monitoring & Low Battery Notification

    private func setupBatteryMonitoring() {
        Task { @MainActor in
            let (id, stream) = await manager.eventBus.subscribe()
            await updateBatteryInfo()
            for await event in stream {
                if event.kind == OfbEventKind.stateChanged || event.kind == OfbEventKind.deviceChanged ||
                   (event.kind == OfbEventKind.propertyChanged && (event.group == "battery" || event.group == nil)) {
                    await updateBatteryInfo()
                    if event.kind == OfbEventKind.stateChanged && manager.state == .connected {
                        await manager.requestBatteryUpdate()
                    }
                }
            }
            await manager.eventBus.unsubscribe(id: id)
        }

        Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 15_000_000_000)
                if manager.state == .connected {
                    await manager.requestBatteryUpdate()
                    await updateBatteryInfo()
                }
            }
        }
    }

    public func updateBatteryInfo() async {
        guard manager.state == .connected else {
            self.batteryPercentage = nil
            self.batteryText = nil
            self.didNotify20 = false
            self.didNotify10 = false
            return
        }

        if let battery = await manager.getProperty(group: "battery", prop: nil, fallback: nil) as? [String: Any] {
            let global = battery["global"] as? Int
            let left = battery["left"] as? Int
            let right = battery["right"] as? Int
            let caseBat = battery["case"] as? Int

            var parts: [String] = []
            if config.showLeftBatteryInTray, let l = left {
                parts.append("L:\(l)%")
            }
            if config.showRightBatteryInTray, let r = right {
                parts.append("R:\(r)%")
            }
            if config.showCaseBatteryInTray, let c = caseBat {
                parts.append("C:\(c)%")
            }

            if !parts.isEmpty {
                self.batteryText = parts.joined(separator: " ")
            } else if let g = global, g > 0 {
                self.batteryText = "\(g)%"
            } else if let l = left {
                self.batteryText = "L:\(l)%"
            } else if let r = right {
                self.batteryText = "R:\(r)%"
            } else {
                self.batteryText = nil
            }

            let validPcts = [left, right, global].compactMap { $0 }
            self.batteryPercentage = validPcts.isEmpty ? nil : validPcts.min()

            if let pct = self.batteryPercentage {
                checkLowBattery(pct)
            }
        } else {
            self.batteryText = nil
            self.batteryPercentage = nil
        }
    }

    private func checkLowBattery(_ percentage: Int) {
        guard config.notifyLowBattery else { return }
        if percentage <= 0 {
            return
        }
        if percentage <= 10 && !didNotify10 {
            didNotify10 = true
            sendLowBatteryNotification(
                title: "⚠️ Battery Critical",
                body: "\(manager.deviceName): Battery at \(percentage)%. Please charge your earbuds soon."
            )
        } else if percentage <= 20 && !didNotify20 {
            didNotify20 = true
            sendLowBatteryNotification(
                title: "🔋 Low Battery",
                body: "\(manager.deviceName): Battery at \(percentage)%."
            )
        } else if percentage > 20 {
            didNotify20 = false
            didNotify10 = false
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    // MARK: - UNUserNotificationCenterDelegate

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner + list + sound even when app is active (critical for menu bar apps)
        if #available(macOS 11.0, *) {
            completionHandler([.banner, .list, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }

    private func sendLowBatteryNotification(title: String, body: String) {
        guard config.notifyLowBattery else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        if #available(macOS 12.0, *) {
            content.interruptionLevel = .timeSensitive
        }

        let notifId = "low_battery_\(UUID().uuidString)"
        let request = UNNotificationRequest(
            identifier: notifId,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)

        // Auto hide notification after 3 seconds
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [notifId])
        }
    }

    // MARK: - Auto Start

    private func autoStartDevice() async {
        if !config.deviceName.isEmpty && !config.deviceAddress.isEmpty {
            do {
                try await manager.start(deviceName: config.deviceName, deviceAddress: config.deviceAddress)
            } catch {}
            return
        }

        if config.autoSetup {
            let paired = await BluetoothManager.shared.listPairedDevices()
            // Prefer connected supported device first, then any supported paired device
            if let target = paired.first(where: { DeviceRegistry.isSupported($0.name) && $0.isConnected }) ?? paired.first(where: { DeviceRegistry.isSupported($0.name) }) {
                config.setDeviceData(name: target.name, address: target.address)
                try? await manager.start(deviceName: target.name, deviceAddress: target.address)
            }
        }
    }
}
