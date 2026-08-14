// OFBCore/Driver/DeviceRegistry.swift

import Foundation

public enum DeviceRegistry {
    public static let deviceToDriver: [String: @Sendable (String) -> BaseDriver] = [
        "Debug: Virtual device": { VirtualDeviceDriver(address: $0) },
        "HONOR Earbuds 2": { FreeBuds4iDriver(address: $0) },
        "HONOR Earbuds 2 SE": { FreeBuds4iDriver(address: $0) },
        "HONOR Earbuds 2 Lite": { FreeBuds4iDriver(address: $0) },
        "HUAWEI FreeBuds 4i": { FreeBuds4iDriver(address: $0) },
        "HUAWEI FreeBuds 5i": { FreeBuds5iDriver(address: $0) },
        "HUAWEI FreeBuds 6i": { FreeBuds6iDriver(address: $0) },
        "HUAWEI FreeBuds Pro": { FreeBudsProDriver(address: $0) },
        "HUAWEI FreeBuds Pro 2": { FreeBudsPro2Driver(address: $0) },
        "HUAWEI FreeBuds Pro 3": { FreeBudsPro3Driver(address: $0) },
        "HUAWEI FreeBuds Pro 4": { FreeBudsPro3Driver(address: $0) },
        "HUAWEI FreeBuds Pro 5": { FreeBudsPro5Driver(address: $0) },
        "HUAWEI FreeClip": { FreeBudsPro3Driver(address: $0) },
        "HUAWEI FreeClip 2": { FreeClip2Driver(address: $0) },
        "HUAWEI FreeBuds SE": { FreeBudsSEDriver(address: $0) },
        "HUAWEI FreeBuds SE 2": { FreeBudsSE2Driver(address: $0) },
        "HUAWEI FreeBuds SE 4 ANC": { FreeBudsSE4Driver(address: $0) },
        "HUAWEI FreeBuds Studio": { FreeBudsStudioDriver(address: $0) },
        "HUAWEI FreeLace Pro": { FreeLaceProDriver(address: $0) },
        "HUAWEI FreeLace Pro 2": { FreeLacePro2Driver(address: $0) }
    ]

    public static func isHuaweiOrHonorDevice(_ name: String) -> Bool {
        if deviceToDriver[name] != nil {
            return true
        }
        let upper = name.uppercased()
        return upper.contains("HUAWEI") || upper.contains("HONOR") || upper.contains("FREEBUDS") || upper.contains("EARBUDS") || upper.contains("FREECLIP") || upper.contains("FREELACE")
    }

    public static func isSupported(_ name: String) -> Bool {
        return isHuaweiOrHonorDevice(name)
    }

    public static func createDriver(name: String, address: String) -> BaseDriver? {
        // 1. Check official supported Huawei/Honor device list
        if let builder = deviceToDriver[name] {
            return builder(address)
        }

        // 2. Check if it's an unlisted Huawei / Honor device -> GenericHuaweiDriver (SPP)
        if isHuaweiOrHonorDevice(name) {
            return GenericHuaweiDriver(address: address)
        }

        // 3. Non-Huawei / Third-party device outside GenericHuaweiDriver -> BLEBatteryDriver
        return BLEBatteryDriver(address: address)
    }

    public static var supportedDeviceNames: [String] {
        Array(deviceToDriver.keys).sorted()
    }
}
