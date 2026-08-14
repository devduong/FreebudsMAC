// OFBCore/Handler/OtherHandlers.swift

import Foundation

// MARK: - Sound Quality Preference Handler

public final class SoundQualityHandler: HuaweiHandler, @unchecked Sendable {
    public let handlerId: String = "sound_quality"
    public let properties: [(group: String, prop: String)] = [("sound", "quality_preference")]

    // commands = [0x2ba3], ignore_commands = [0x2ba2]
    private let cmdRead = Data([0x2b, 0xa3])
    private let cmdWrite = Data([0x2b, 0xa2])

    public var commands: [Data] { [cmdRead] }
    public var ignoreCommands: [Data] { [cmdWrite] }
    public weak var driver: HuaweiDriver?

    private let options: [Int8: String] = [
        0: "sqp_connectivity",
        1: "sqp_quality"
    ]

    public init() {}

    public func onInit() async throws {
        let readReq = HuaweiPacket.readRequest(cmd: cmdRead, parameterTypes: [1])
        if let resp = try await driver?.sendPackage(readReq) {
            await onPackage(resp)
        }
    }

    public func onPackage(_ package: HuaweiPacket) async {
        // Read parameter 2 from response
        let value = package.findParam(2)
        if value.count == 1 {
            let signed = Int8(bitPattern: value[0])
            let str = options[signed] ?? "\(signed)"
            await driver?.putProperty(group: "sound", prop: "quality_preference", value: str, extendGroup: true)
            await driver?.putProperty(group: "sound", prop: "quality_preference_options",
                                       value: options.values.joined(separator: ","), extendGroup: true)
        }
    }

    public func setProperty(group: String, prop: String, value: String) async throws {
        guard let byteVal = reverseDictInt8(options)[value] else { return }
        let pkg = HuaweiPacket.changeRequest(cmd: cmdWrite, parameters: [(1, Data([UInt8(bitPattern: byteVal)]))])
        _ = try await driver?.sendPackage(pkg)
        try await onInit()
    }
}

// MARK: - Low Latency Handler

public final class LowLatencyHandler: HuaweiHandler, @unchecked Sendable {
    public let handlerId: String = "low_latency"
    public let properties: [(group: String, prop: String)] = [("config", "low_latency")]

    // CMD_LOW_LATENCY = 0x2b6c
    private let cmd = Data([0x2b, 0x6c])

    public var commands: [Data] { [cmd] }
    public let ignoreCommands: [Data] = []
    public weak var driver: HuaweiDriver?

    public init() {}

    public func onInit() async throws {
        // Read parameter 2
        let readReq = HuaweiPacket.readRequest(cmd: cmd, parameterTypes: [2])
        if let resp = try await driver?.sendPackage(readReq) {
            await onPackage(resp)
        }
    }

    public func onPackage(_ package: HuaweiPacket) async {
        // Read parameter 2
        let value = package.findParam(2)
        guard !value.isEmpty else { return }

        let enabled = value[0] == 0x01
        await driver?.putProperty(group: "config", prop: "low_latency", value: enabled ? "true" : "false", extendGroup: true)
    }

    public func setProperty(group: String, prop: String, value: String) async throws {
        let enabled = (value == "true")
        let byteVal: UInt8 = enabled ? 0x01 : 0x00
        let pkg = HuaweiPacket.changeRequest(cmd: cmd, parameters: [(1, Data([byteVal]))])
        _ = try await driver?.sendPackage(pkg)
        // Wait 1s then refresh state
        try await Task.sleep(nanoseconds: 1_000_000_000)
        try await onInit()
    }
}

// MARK: - In-Ear State Handler (Wear Detection)

public final class InEarStateHandler: HuaweiHandler, @unchecked Sendable {
    public let handlerId: String = "tws_in_ear"
    public let properties: [(group: String, prop: String)] = []
    public let commands: [Data] = [Data([0x2b, 0x03])]
    public let ignoreCommands: [Data] = []
    public weak var driver: HuaweiDriver?

    public init() {}

    public func onInit() async throws {
        // Do not force "false" on init so active wearing status is preserved
    }

    public func onPackage(_ package: HuaweiPacket) async {
        let hexCmd = package.commandId.map { String(format: "%02X", $0) }.joined()
        let paramSummary = package.parameters.keys.sorted().map { k in
            let v = package.parameters[k]!
            let hex = v.map { String(format: "%02X", $0) }.joined(separator: " ")
            let dec = v.map { "\($0)" }.joined(separator: ",")
            return "p\(k)=Data(\(v.count)b)[hex: \(hex), dec: \(dec)]"
        }.joined(separator: "; ")

        NSLog("[OFB-InEar] Received in_ear package cmd %@ with params: %@", hexCmd, paramSummary)

        // Check parameters 8, 9 for wear change notification
        let value = package.findParam(8, 9)
        if !value.isEmpty {
            let isInEar = (value[0] == 0x01)
            NSLog("[OFB-InEar] Wear state notification received: in_ear = %@", isInEar ? "true" : "false")
            await driver?.putProperty(group: "state", prop: "in_ear", value: isInEar ? "true" : "false", extendGroup: true)
            return
        }

        if let param1 = package.parameters[1], !param1.isEmpty {
            let isInEar = param1.contains(0x01)
            NSLog("[OFB-InEar] Wear state updated via p1: in_ear = %@", isInEar ? "true" : "false")
            await driver?.putProperty(group: "state", prop: "in_ear", value: isInEar ? "true" : "false", extendGroup: true)
        }
    }

    public func setProperty(group: String, prop: String, value: String) async throws {}
}

// MARK: - Voice Language Handler

public final class VoiceLanguageHandler: HuaweiHandler, @unchecked Sendable {
    public let handlerId: String = "service_language"
    public let properties: [(group: String, prop: String)] = [("service", "language")]

    // commands = [0x0c02], ignore_commands = [0x0c01]
    private let cmdRead = Data([0x0c, 0x02])
    private let cmdWrite = Data([0x0c, 0x01])

    public var commands: [Data] { [cmdRead] }
    public var ignoreCommands: [Data] { [cmdWrite] }
    public weak var driver: HuaweiDriver?

    public init() {}

    public func onInit() async throws {
        // Read parameters 1 and 2
        let readReq = HuaweiPacket.readRequest(cmd: cmdRead, parameterTypes: [1, 2])
        if let resp = try await driver?.sendPackage(readReq) {
            await onPackage(resp)
        }
    }

    public func onPackage(_ package: HuaweiPacket) async {
        // Read parameter 3 for locale list
        if let param3 = package.parameters[3], param3.count > 1 {
            let locales = String(data: param3, encoding: .utf8) ?? ""
            await driver?.putProperty(group: "service", prop: "language", value: "", extendGroup: true)
            await driver?.putProperty(group: "service", prop: "language_options", value: locales, extendGroup: true)
        }
    }

    public func setProperty(group: String, prop: String, value: String) async throws {
        let langBytes = value.data(using: .utf8) ?? Data()
        let pkg = HuaweiPacket.changeRequest(cmd: cmdWrite, parameters: [
            (1, langBytes),
            (2, Data([0x01]))
        ])
        _ = try await driver?.sendPackage(pkg)
    }
}

// MARK: - Logs Handler

public final class LogsHandler: HuaweiHandler, @unchecked Sendable {
    public let handlerId: String = "logs"
    public let properties: [(group: String, prop: String)] = []
    public let commands: [Data] = [Data([0x2b, 0x0a])]
    public let ignoreCommands: [Data] = []
    public weak var driver: HuaweiDriver?

    public init() {}

    public func onInit() async throws {}
    public func onPackage(_ package: HuaweiPacket) async {}
    public func setProperty(group: String, prop: String, value: String) async throws {}
}

// MARK: - Dual Connect Handler

public struct DualConnectDevice: Codable, Identifiable, Sendable {
    public var id: String { mac }
    public let mac: String
    public let name: String
    public let connected: Bool
    public let playing: Bool
    public let preferred: Bool
    public let autoConnect: Bool?
}

public final class DualConnectHandler: HuaweiHandler, @unchecked Sendable {
    public let handlerId: String = "dual_connect"
    public let properties: [(group: String, prop: String)] = [
        ("dual_connect", "enabled"),
        ("dual_connect", "devices"),
        ("dual_connect", "preferred_device")
    ]
    public let commands: [Data] = [
        Data([0x2b, 0x31]), // CMD_DUAL_CONNECT_ENUMERATE
        Data([0x2b, 0x36]), // CMD_DUAL_CONNECT_CHANGE_EVENT
        Data([0x2b, 0x2f])  // CMD_DUAL_CONNECT_ENABLED_READ
    ]
    public let ignoreCommands: [Data] = [
        Data([0x2b, 0x32]), // CMD_DUAL_CONNECT_PREFERRED_WRITE
        Data([0x2b, 0x33]), // CMD_DUAL_CONNECT_EXECUTE
        Data([0x2b, 0x2e])  // CMD_DUAL_CONNECT_ENABLED_WRITE
    ]
    public weak var driver: HuaweiDriver?

    private var pendingDevices: [String: DualConnectDevice] = [:]
    private var expectedDeviceCount: Int = 999

    public init() {}

    private func parseBigEndianInt(_ data: Data?) -> Int {
        guard let data = data, !data.isEmpty else { return 0 }
        var val: Int = 0
        for byte in data {
            val = (val << 8) | Int(byte)
        }
        return val
    }

    public func onInit() async throws {
        // Read enabled toggle state (0x2b 0x2f)
        let readEnabled = HuaweiPacket.readRequest(cmd: Data([0x2b, 0x2f]), parameterTypes: [1])
        if let resp = try await driver?.sendPackage(readEnabled, timeout: 1.5) {
            await onPackage(resp)
        }

        // Send enumeration request (0x2b 0x31)
        pendingDevices = [:]
        expectedDeviceCount = 999
        let enumReq = HuaweiPacket.changeRequest(cmd: Data([0x2b, 0x31]), parameters: [(1, Data())])
        _ = try? await driver?.sendPackage(enumReq, timeout: 1.5)
    }

    public func onPackage(_ package: HuaweiPacket) async {
        // 1. Change event (0x2b 0x36) -> Re-init device list
        if package.commandId == Data([0x2b, 0x36]) {
            try? await onInit()
            return
        }

        // 2. Enabled read response (0x2b 0x2f)
        if package.commandId == Data([0x2b, 0x2f]) {
            if let param1 = package.parameters[1], !param1.isEmpty {
                let isEnabled = (param1[0] == 0x01)
                await driver?.putProperty(group: "dual_connect", prop: "enabled", value: isEnabled ? "true" : "false", extendGroup: true)
            }
            return
        }

        // 3. Enumeration packet response (0x2b 0x31)
        if package.commandId == Data([0x2b, 0x31]) {
            guard let macData = package.parameters[4], macData.count >= 6 else { return }
            let macHex = macData.map { String(format: "%02x", $0) }.joined()

            if let param2 = package.parameters[2] {
                expectedDeviceCount = parseBigEndianInt(param2)
            }

            let nameData = package.parameters[9] ?? Data()
            var nameStr = String(data: nameData, encoding: .utf8) ?? ""
            nameStr = nameStr.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "\0")))
            if nameStr.isEmpty {
                nameStr = "Bluetooth Device (\(macHex.suffix(4).uppercased()))"
            }

            let connState = package.parameters[5]?.first ?? 0
            let isConnected = (connState > 0)
            let isPlaying = (connState == 9)

            let isPreferred = (package.parameters[7]?.first == 1)
            let autoConn = (package.parameters[8]?.first == 1)

            let dev = DualConnectDevice(
                mac: macHex,
                name: nameStr,
                connected: isConnected,
                playing: isPlaying,
                preferred: isPreferred,
                autoConnect: autoConn
            )

            pendingDevices[macHex] = dev

            // Always update and publish stored devices dictionary in real-time as packets arrive
            await processPendingDevices()
        }
    }

    private func processPendingDevices() async {
        var devicesMap: [String: [String: String]] = [:]
        var preferredMac = "000000000000"

        for dev in pendingDevices.values {
            devicesMap[dev.mac] = [
                "name": dev.name,
                "connected": dev.connected ? "true" : "false",
                "playing": dev.playing ? "true" : "false",
                "preferred": dev.preferred ? "true" : "false",
                "auto_connect": (dev.autoConnect == true) ? "true" : "false"
            ]
            if dev.preferred {
                preferredMac = dev.mac
            }
        }

        if let jsonData = try? JSONSerialization.data(withJSONObject: devicesMap),
           let jsonStr = String(data: jsonData, encoding: .utf8) {
            await driver?.putProperty(group: "dual_connect", prop: "devices", value: jsonStr, extendGroup: true)
        }
        await driver?.putProperty(group: "dual_connect", prop: "preferred_device", value: preferredMac, extendGroup: true)
    }

    public func setProperty(group: String, prop: String, value: String) async throws {
        if prop == "enabled" {
            let enabledByte: UInt8 = (value == "true") ? 0x01 : 0x00
            let pkg = HuaweiPacket.changeRequest(cmd: Data([0x2b, 0x2e]), parameters: [(1, Data([enabledByte]))])
            _ = try await driver?.sendPackage(pkg)
            try await onInit()
            return
        }

        if prop == "preferred_device" {
            let macBytes = Data(hexString: value)
            let pkg = HuaweiPacket.changeRequest(cmd: Data([0x2b, 0x32]), parameters: [(1, macBytes)])
            _ = try await driver?.sendPackage(pkg)
            try await onInit()
            return
        }

        if prop == "refresh" {
            try await onInit()
            return
        }

        let parts = prop.split(separator: ":")
        if parts.count >= 2 {
            let macHex = String(parts[0])
            let actionName = String(parts[1])
            let macBytes = Data(hexString: macHex)

            var actionCode: UInt8 = 0
            if actionName == "connected" {
                actionCode = (value == "true") ? 1 : 2
            } else if actionName == "auto_connect" {
                actionCode = (value == "true") ? 4 : 5
            } else if actionName == "unpair" {
                actionCode = 3
            }

            if actionCode > 0 {
                let pkg = HuaweiPacket.changeRequest(cmd: Data([0x2b, 0x33]), parameters: [(actionCode, macBytes)])
                _ = try await driver?.sendPackage(pkg)
                try await onInit()
            }
        }
    }
}

extension Data {
    init(hexString: String) {
        var data = Data()
        var hex = hexString
        if hex.count % 2 != 0 { hex = "0" + hex }
        var index = hex.startIndex
        while index < hex.endIndex {
            let nextIndex = hex.index(index, offsetBy: 2)
            if let byte = UInt8(hex[index..<nextIndex], radix: 16) {
                data.append(byte)
            }
            index = nextIndex
        }
        self = data
    }
}

// MARK: - Reverse Dict Utility (Int8 version for OtherHandlers)

private func reverseDictInt8(_ dict: [Int8: String]) -> [String: Int8] {
    var result: [String: Int8] = [:]
    for (k, v) in dict {
        result[v] = k
    }
    return result
}
