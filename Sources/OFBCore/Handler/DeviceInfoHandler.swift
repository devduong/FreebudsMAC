// OFBCore/Handler/DeviceInfoHandler.swift

import Foundation

public final class DeviceInfoHandler: HuaweiHandler, @unchecked Sendable {
    public let handlerId: String = "info"
    public let properties: [(group: String, prop: String)] = []
    public let commands: [Data] = [Data([0x2b, 0x06])]
    public let ignoreCommands: [Data] = []

    public weak var driver: HuaweiDriver?

    public init() {}

    public func setProperty(group: String, prop: String, value: String) async throws {}

    public func onInit() async throws {
        let readReq = HuaweiPacket.readRequest(cmd: Data([0x2b, 0x06]), parameterTypes: [1, 2, 3, 4])
        if let resp = try await driver?.sendPackage(readReq) {
            await onPackage(resp)
        }
    }

    public func onPackage(_ package: HuaweiPacket) async {
        var out: [String: String] = [:]

        if let nameData = package.parameters[1], let name = String(data: nameData, encoding: .utf8) {
            out["device_name"] = name
        }
        if let fwData = package.parameters[2], let fw = String(data: fwData, encoding: .utf8) {
            out["firmware_version"] = fw
        }
        if let snData = package.parameters[3], let sn = String(data: snData, encoding: .utf8) {
            out["serial_number"] = sn
        }

        await driver?.putProperty(group: "info", prop: nil, value: out, extendGroup: false)
    }
}
