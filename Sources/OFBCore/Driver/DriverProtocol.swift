// OFBCore/Driver/DriverProtocol.swift

import Foundation
import OFBBluetooth

// MARK: - Driver Handler Protocol

public protocol DriverHandler: AnyObject, Sendable {
    var handlerId: String { get }
    var properties: [(group: String, prop: String)] { get }

    func setProperty(group: String, prop: String, value: String) async throws
}

// MARK: - Driver Protocol

public protocol OfbDriver: AnyObject, Sendable {
    var deviceAddress: String { get }
    var started: Bool { get }
    var eventBus: EventBus { get }

    func isDeviceOnline() async -> Bool
    func start() async throws
    func stop() async
    func healthy() -> Bool
    func getHealthReport() async -> [String: Any]

    func getProperty(group: String?, prop: String?, fallback: Any?) async -> Any?
    func setProperty(group: String, prop: String, value: String) async throws
    func putProperty(group: String?, prop: String?, value: Any?, extendGroup: Bool) async
}

// MARK: - Base Driver Implementation

open class BaseDriver: OfbDriver, @unchecked Sendable {
    public let deviceAddress: String
    public private(set) var started: Bool = false
    public let eventBus = EventBus()

    private var store: [String: [String: Any]] = [:]
    private var setPropHandlers: [String: DriverHandler] = [:]
    private let lock = NSLock()

    public init(address: String) {
        self.deviceAddress = address
    }

    open func isDeviceOnline() async -> Bool {
        let result = await BluetoothManager.shared.isConnectedAsync(address: deviceAddress)
        if result == nil {
            NSLog("[OFB-Driver] isDeviceOnline: device %@ NOT FOUND by BluetoothManager", deviceAddress)
        }
        return result ?? false
    }

    open func start() async throws {
        started = true
    }

    open func stop() async {
        lock.withLock {
            setPropHandlers.removeAll()
        }
        started = false
    }

    open func healthy() -> Bool {
        started
    }

    open func getHealthReport() async -> [String : Any] {
        lock.withLock {
            [
                "started": started,
                "address": deviceAddress,
                "store_content": store,
                "available_store_handlers": Array(setPropHandlers.keys)
            ]
        }
    }

    public func addSetPropertyHandler(_ handler: DriverHandler) {
        lock.withLock {
            for (group, prop) in handler.properties {
                let targetId = "\(group)//\(prop)"
                setPropHandlers[targetId] = handler
            }
        }
    }

    open func setProperty(group: String, prop: String, value: String) async throws {
        let targetId = "\(group)//\(prop)"
        let groupTargetId = "\(group)//"

        let handler: DriverHandler? = lock.withLock {
            setPropHandlers[targetId] ?? setPropHandlers[groupTargetId]
        }

        guard let h = handler else {
            throw NSError(domain: "OFBCore", code: 404, userInfo: [NSLocalizedDescriptionKey: "No handler for \(targetId)"])
        }
        try await h.setProperty(group: group, prop: prop, value: value)
    }

    open func getProperty(group: String? = nil, prop: String? = nil, fallback: Any? = nil) async -> Any? {
        lock.withLock {
            guard let group = group else {
                return store
            }
            guard let groupData = store[group] else {
                return fallback
            }
            guard let prop = prop else {
                return groupData
            }
            return groupData[prop] ?? fallback
        }
    }

    open func putProperty(group: String?, prop: String?, value: Any?, extendGroup: Bool = false) async {
        lock.withLock {
            if group == nil {
                if let dictVal = value as? [String: [String: Any]] {
                    store = dictVal
                }
            } else if let g = group {
                if prop == nil && extendGroup {
                    var current = store[g] ?? [:]
                    if let dictVal = value as? [String: Any] {
                        current.merge(dictVal) { _, new in new }
                    }
                    store[g] = current
                } else if let p = prop {
                    if store[g] == nil {
                        store[g] = [:]
                    }
                    if let val = value {
                        store[g]?[p] = val
                    } else {
                        store[g]?.removeValue(forKey: p)
                    }
                } else {
                    if let dictVal = value as? [String: Any] {
                        store[g] = dictVal
                    } else if value == nil {
                        store.removeValue(forKey: g)
                    }
                }
            }
        }

        await eventBus.send(OfbEvent(
            kind: OfbEventKind.propertyChanged,
            group: group,
            prop: prop,
            value: value
        ))
    }
}
