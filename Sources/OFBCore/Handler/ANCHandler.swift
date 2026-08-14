// OFBCore/Handler/ANCHandler.swift

import Foundation

public final class ANCLegacyHandler: HuaweiHandler, @unchecked Sendable {
    public let handlerId: String = "anc_change"
    public let properties: [(group: String, prop: String)] = []
    public let commands: [Data] = [Data([0x2b, 0x03])]
    public let ignoreCommands: [Data] = []

    public weak var driver: HuaweiDriver?

    public init() {}

    public func setProperty(group: String, prop: String, value: String) async throws {}

    public func onInit() async throws {}

    public func onPackage(_ package: HuaweiPacket) async {
        let data = package.findParam(1)
        if data.count == 1 && data[0] <= 2 {
            let req = HuaweiPacket(cmd: Data([0x2b, 0x2a]), parametersList: [(1, Data())])
            _ = try? await driver?.sendPackage(req)
        }
    }
}

public final class ANCHandler: HuaweiHandler, @unchecked Sendable {
    public let handlerId: String = "anc_global"
    public let properties: [(group: String, prop: String)] = [
        ("anc", "mode"),
        ("anc", "level")
    ]
    public let commands: [Data] = [Data([0x2b, 0x2a])]
    public let ignoreCommands: [Data] = [Data([0x2b, 0x04])]

    public weak var driver: HuaweiDriver?

    public let withCancelLevel: Bool
    public let withVoiceBoost: Bool
    public private(set) var activeMode: UInt8 = 0

    public let modeOptions: [UInt8: String] = [
        0: "normal",
        1: "cancellation",
        2: "awareness"
    ]

    public var cancelLevelOptions: [UInt8: String] = [
        1: "comfort",
        0: "normal",
        2: "ultra"
    ]

    public let awarenessLevelOptions: [UInt8: String] = [
        1: "voice_boost",
        2: "normal"
    ]

    public init(withCancelLevel: Bool = false, withCancelDynamic: Bool = false, withVoiceBoost: Bool = false) {
        self.withCancelLevel = withCancelLevel
        self.withVoiceBoost = withVoiceBoost
        if withCancelDynamic {
            self.cancelLevelOptions[3] = "dynamic"
        }
    }

    public func onInit() async throws {
        let readReq = HuaweiPacket.readRequest(cmd: Data([0x2b, 0x2a]), parameterTypes: [1, 2])
        if let resp = try await driver?.sendPackage(readReq) {
            await onPackage(resp)
        }
    }

    public func onPackage(_ package: HuaweiPacket) async {
        let data = package.findParam(1)
        guard data.count == 2 else { return }

        self.activeMode = data[1]
        let modeStr = modeOptions[data[1]] ?? "\(data[1])"
        let modeOptionsStr = modeOptions.values.joined(separator: ",")

        var newProps: [String: String] = [
            "mode": modeStr,
            "mode_options": modeOptionsStr
        ]

        if data[1] == 1 && withCancelLevel {
            let lvlStr = cancelLevelOptions[data[0]] ?? "\(data[0])"
            newProps["level"] = lvlStr
            newProps["level_options"] = cancelLevelOptions.values.joined(separator: ",")
        } else if data[1] == 2 && withVoiceBoost {
            let lvlStr = awarenessLevelOptions[data[0]] ?? "\(data[0])"
            newProps["level"] = lvlStr
            newProps["level_options"] = awarenessLevelOptions.values.joined(separator: ",")
        }

        await driver?.putProperty(group: "anc", prop: nil, value: newProps, extendGroup: false)
    }

    public func setProperty(group: String, prop: String, value: String) async throws {
        var options: [UInt8: String]
        if prop == "mode" {
            options = modeOptions
        } else if activeMode != 2 {
            options = cancelLevelOptions
        } else {
            options = awarenessLevelOptions
        }

        guard let keyByte = options.first(where: { $0.value == value })?.key else {
            throw NSError(domain: "OFBCore", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid option \(value)"])
        }

        let data: Data
        if prop == "mode" {
            data = Data([keyByte, keyByte == 0 ? 0x00 : 0xFF])
        } else {
            data = Data([activeMode, keyByte])
        }

        let pkg = HuaweiPacket.changeRequest(cmd: Data([0x2b, 0x04]), parameters: [(1, data)])
        _ = try await driver?.sendPackage(pkg)
        try await onInit()
    }
}
