// OFBBluetooth/BluetoothManager.swift
//
// Provides Bluetooth device discovery, connection and disconnection
// using IOBluetooth framework natively.

@preconcurrency import Foundation
@preconcurrency import IOBluetooth

// MARK: - Data Types

/// Represents a paired Bluetooth device discovered via IOBluetooth.
public struct PairedDevice: Identifiable, Hashable, Sendable {
    public let id: String          // MAC address (canonical form)
    public let name: String
    public let address: String     // Canonical colon-separated uppercase
    public let isConnected: Bool

    public init(name: String, address: String, isConnected: Bool) {
        self.name = name
        self.address = Self.canonicalAddress(address)
        self.isConnected = isConnected
        self.id = self.address
    }

    /// Normalize a Bluetooth MAC to colon-separated upper-case form.
    public static func canonicalAddress(_ addr: String) -> String {
        addr.replacingOccurrences(of: "-", with: ":").uppercased()
    }
}

// MARK: - BluetoothManager

/// Manages Bluetooth device interactions via IOBluetooth.
public final class BluetoothManager: @unchecked Sendable {
    public static let shared = BluetoothManager()

    private init() {}

    // MARK: - Device Lookup

    /// Find an IOBluetoothDevice by MAC address.
    ///
    /// Checks paired devices array first to ensure we get the active system instance
    /// whose `isConnected` state is updated by macOS bluetoothd.
    public func findDevice(address: String) -> IOBluetoothDevice? {
        let canonical = PairedDevice.canonicalAddress(address)
        
        // 1. Search active paired devices list first
        if let paired = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] {
            for dev in paired {
                if let rawAddr = dev.addressString, PairedDevice.canonicalAddress(rawAddr) == canonical {
                    return dev
                }
            }
        }
        
        // 2. Fallback to address string lookup
        if let device = IOBluetoothDevice(addressString: canonical) {
            return device
        }
        let dashForm = canonical.replacingOccurrences(of: ":", with: "-").lowercased()
        return IOBluetoothDevice(addressString: dashForm)
    }

    // MARK: - Connection Status

    /// Check if a device is currently connected.
    ///
    /// Returns `nil` if the device is not found, `true`/`false` otherwise.
    public func isConnected(address: String) -> Bool? {
        guard let device = findDevice(address: address) else {
            return nil
        }
        let connected = device.isConnected()
        NSLog("[OFB-Bluetooth] isConnected for %@ (%@): %d", device.name ?? "?", address, connected ? 1 : 0)
        return connected
    }

    /// Async version of `isConnected`.
    public func isConnectedAsync(address: String) async -> Bool? {
        return isConnected(address: address)
    }

    // MARK: - Connect / Disconnect

    /// Open a Bluetooth connection to the device.
    ///
    /// Runs `openConnection()` on a background thread to avoid blocking.
    /// Returns `true` on success, `false` on failure, `nil` if device not found.
    public func connect(address: String) async -> Bool? {
        guard let device = findDevice(address: address) else {
            return nil
        }
        do {
            let result: Bool = try await withCheckedThrowingContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    let err = device.openConnection()
                    if err == kIOReturnSuccess {
                        continuation.resume(returning: true)
                    } else {
                        continuation.resume(returning: false)
                    }
                }
            }
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            return result
        } catch {
            return false
        }
    }

    /// Close the Bluetooth connection to the device.
    ///
    /// Returns `true` on success, `false` on failure, `nil` if device not found.
    public func disconnect(address: String) async -> Bool? {
        guard let device = findDevice(address: address) else {
            return nil
        }
        do {
            let result: Bool = try await withCheckedThrowingContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    let err = device.closeConnection()
                    if err == kIOReturnSuccess {
                        continuation.resume(returning: true)
                    } else {
                        continuation.resume(returning: false)
                    }
                }
            }
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            return result
        } catch {
            return false
        }
    }

    // MARK: - Device Discovery

    /// List all paired Bluetooth devices.
    public func listPairedDevices() async -> [PairedDevice] {
        var results: [PairedDevice] = []

        guard let devices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else {
            return results
        }

        for device in devices {
            let name = device.name ?? device.nameOrAddress ?? "(unnamed)"
            guard let rawAddr = device.addressString, !rawAddr.isEmpty else {
                continue
            }
            let addr = PairedDevice.canonicalAddress(rawAddr)
            let connected = device.isConnected()

            results.append(PairedDevice(
                name: name,
                address: addr,
                isConnected: connected
            ))
        }

        return results
    }
}
