// OFBCore/Handler/AutoPauseHandler.swift

import Foundation

public final class AutoPauseHandler: HuaweiHandler, @unchecked Sendable {
    public let handlerId: String = "config_auto_pause"
    public let properties: [(group: String, prop: String)] = [
        ("config", "auto_pause")
    ]

    // CMD_AUTO_PAUSE_READ = 0x2b11, CMD_AUTO_PAUSE_WRITE = 0x2b10
    private let cmdRead = Data([0x2b, 0x11])
    private let cmdWrite = Data([0x2b, 0x10])

    public var commands: [Data] { [cmdRead, cmdWrite] }
    public let ignoreCommands: [Data] = []

    public weak var driver: HuaweiDriver?

    public init() {}

    public func onInit() async throws {
        let readReq = HuaweiPacket.readRequest(cmd: cmdRead, parameterTypes: [1])
        if let resp = try await driver?.sendPackage(readReq) {
            await onPackage(resp)
        }
    }

    public func onPackage(_ package: HuaweiPacket) async {
        let data = package.findParam(1)
        if data.count == 1 {
            let enabled = data[0] == 0x01
            await driver?.putProperty(group: "config", prop: "auto_pause", value: enabled ? "true" : "false", extendGroup: false)
        }
    }

    public func setProperty(group: String, prop: String, value: String) async throws {
        let enabled = (value == "true")
        let valByte: UInt8 = enabled ? 0x01 : 0x00
        let pkg = HuaweiPacket.changeRequest(cmd: cmdWrite, parameters: [(1, Data([valByte]))])
        let resp = try await driver?.sendPackage(pkg)
        if let resp = resp, !resp.findParam(127).isEmpty {
            await driver?.putProperty(group: group, prop: prop, value: value, extendGroup: false)
        }
    }
}
