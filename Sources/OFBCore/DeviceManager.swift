// OFBCore/DeviceManager.swift

import Foundation
import Combine

@MainActor
public final class DeviceManager: ObservableObject {
    @Published public private(set) var state: DeviceState = .stopped
    @Published public private(set) var deviceName: String = ""
    @Published public private(set) var deviceAddress: String = ""

    public let eventBus = EventBus()
    public private(set) lazy var shortcuts = Shortcuts(manager: self)

    private var driver: OfbDriver?
    private var mainTask: Task<Void, Never>?
    private var isPaused: Bool = false

    public init() {}

    deinit {
        mainTask?.cancel()
    }

    // MARK: - Lifecycle

    public func start(deviceName: String, deviceAddress: String) async throws {
        await stop()
        guard let newDriver = DeviceRegistry.createDriver(name: deviceName, address: deviceAddress) else {
            throw NSError(domain: "OFBCore", code: 404, userInfo: [NSLocalizedDescriptionKey: "Unknown device \(deviceName)"])
        }

        self.driver = newDriver
        self.deviceName = deviceName
        self.deviceAddress = deviceAddress

        // Run mainloop on background thread so UI is never blocked
        mainTask = Task.detached { [weak self] in
            await self?.mainloop()
        }

        await eventBus.send(OfbEvent(kind: OfbEventKind.deviceChanged))
    }

    public func stop(newState: DeviceState = .stopped) async {
        await setState(newState)
        mainTask?.cancel()
        mainTask = nil

        if let d = driver {
            await d.stop()
            driver = nil
        }

        deviceName = ""
        deviceAddress = ""
    }

    public func destroy() async {
        await stop(newState: .destroyed)
    }

    // MARK: - Properties API

    public func getProperty(group: String? = nil, prop: String? = nil, fallback: Any? = nil) async -> Any? {
        guard let d = driver else { return fallback }
        return await d.getProperty(group: group, prop: prop, fallback: fallback)
    }

    public func setProperty(group: String, prop: String, value: String) async throws {
        guard let d = driver else {
            throw NSError(domain: "OFBCore", code: 400, userInfo: [NSLocalizedDescriptionKey: "Attempt to write prop without active device"])
        }
        try await d.setProperty(group: group, prop: prop, value: value)
    }

    public func requestBatteryUpdate() async {
        guard state == .connected else { return }
        if let huaweiDriver = driver as? HuaweiDriver {
            for handler in huaweiDriver.handlers {
                if let batteryHandler = handler as? BatteryHandler {
                    await batteryHandler.requestBatteryUpdate()
                }
            }
        } else if let bleDriver = driver as? BLEBatteryDriver {
            await bleDriver.requestBatteryUpdate()
        }
    }

    // MARK: - State Machine & Mainloop

    private func setState(_ newState: DeviceState) async {
        await MainActor.run {
            guard self.state != newState else { return }
            self.state = newState
        }
        await eventBus.send(OfbEvent(kind: OfbEventKind.stateChanged, value: newState.rawValue))
    }

    private func getState() async -> DeviceState {
        await MainActor.run { self.state }
    }

    // MARK: - Manual retry (called from UI)
    
    public func retryConnection() async {
        guard state == .connectedLimited || state == .failed else { return }
        NSLog("[OFB-Manager] Manual retry requested by user")
        if let d = driver, d.started {
            await d.stop()
        }
        // Reset mainloop by restarting
        mainTask?.cancel()
        mainTask = Task.detached { [weak self] in
            await self?.mainloop()
        }
    }

    /// Main polling loop.
    /// Runs on a detached background task. Never touches UI directly.
    private func mainloop() async {
        var lastAddress = ""
        var consecutiveFailures = 0
        let maxAutoRetries = 3

        NSLog("[OFB-Manager] mainloop started for device: %@ (%@)", deviceName, deviceAddress)

        while !Task.isCancelled {
            if isPaused {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                continue
            }

            guard let driver = driver else {
                NSLog("[OFB-Manager] mainloop: driver is nil, breaking")
                break
            }

            // Check if macOS reports the device as connected
            let isOnline = await driver.isDeviceOnline()
            if !isOnline {
                let currentState = await getState()
                if currentState != .disconnected {
                    NSLog("[OFB-Manager] Device %@ is offline, setting state to disconnected", deviceAddress)
                }
                await setState(.disconnected)
                if driver.started {
                    NSLog("[OFB-Manager] Stopping driver (device went offline)")
                    await driver.stop()
                }
                consecutiveFailures = 0
                // Sleep 10s when disconnected
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                continue
            }

            // Device is online in macOS — try to start driver (RFCOMM SPP)
            if !driver.started {
                // If we've exceeded max retries, enter limited mode and stop retrying
                if consecutiveFailures >= maxAutoRetries {
                    let currentState = await getState()
                    if currentState != .connectedLimited {
                        NSLog("[OFB-Manager] RFCOMM failed %d times. Entering connectedLimited mode", consecutiveFailures)
                        await setState(.connectedLimited)
                    }
                    // Sleep long and re-check if device is still online
                    try? await Task.sleep(nanoseconds: 30_000_000_000)
                    // If device went offline and came back, reset retry counter
                    let stillOnline = await driver.isDeviceOnline()
                    if !stillOnline {
                        consecutiveFailures = 0
                    }
                    continue
                }

                NSLog("[OFB-Manager] Device online, attempting driver start (attempt #%d/%d)...", consecutiveFailures + 1, maxAutoRetries)
                await setState(.wait)
                do {
                    try await driver.start()
                    NSLog("[OFB-Manager] ✅ Driver started successfully!")
                    await setState(.connected)
                    consecutiveFailures = 0
                    if lastAddress != deviceAddress {
                        await eventBus.send(OfbEvent(kind: OfbEventKind.deviceChanged))
                        lastAddress = deviceAddress
                    }
                } catch {
                    consecutiveFailures += 1
                    NSLog("[OFB-Manager] ❌ Driver start failed (#%d): %@", consecutiveFailures, error.localizedDescription)
                    if consecutiveFailures >= maxAutoRetries {
                        NSLog("[OFB-Manager] Max retries reached. Entering connectedLimited mode.")
                        await setState(.connectedLimited)
                    } else {
                        await setState(.failed)
                        // Backoff: 5s, 10s
                        let backoff = UInt64(consecutiveFailures) * 5
                        NSLog("[OFB-Manager] Will retry in %ds", backoff)
                        try? await Task.sleep(nanoseconds: backoff * 1_000_000_000)
                    }
                    continue
                }
            }

            // Health check
            if !driver.healthy() {
                NSLog("[OFB-Manager] Driver unhealthy, stopping and will retry")
                await driver.stop()
            }

            // Normal polling interval
            try? await Task.sleep(nanoseconds: 2_000_000_000)
        }

        NSLog("[OFB-Manager] mainloop exited")
    }
}

