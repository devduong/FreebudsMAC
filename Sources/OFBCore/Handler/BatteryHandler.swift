// OFBCore/Handler/BatteryHandler.swift
//
// Official Huawei SPP Battery Commands:
//   CMD_BATTERY_READ   = 0x01 0x08 (read request, params [1, 2, 3])
//   CMD_BATTERY_NOTIFY = 0x01 0x27 (push notification from earbuds)
//
// ⚠️ WARNING: Do NOT add 0x2B-prefixed commands here!
//   0x2B is the ANC/config command group prefix. Its raw byte value
//   is decimal 43, which gets misinterpreted as "43% battery" when
//   parsed as a global battery percentage.

import Foundation

public final class BatteryHandler: HuaweiHandler, @unchecked Sendable {
    public let handlerId: String = "battery"
    public let properties: [(group: String, prop: String)] = []

    // Only official Huawei battery commands
    public let commands: [Data] = [
        Data([0x01, 0x08]),  // CMD_BATTERY_READ
        Data([0x01, 0x27])   // CMD_BATTERY_NOTIFY
    ]
    public let ignoreCommands: [Data] = []

    public weak var driver: HuaweiDriver?
    public let withTws: Bool

    public init(withTws: Bool = true) {
        self.withTws = withTws
    }

    public func setProperty(group: String, prop: String, value: String) async throws {}

    public func requestBatteryUpdate() async {
        // Send CMD_BATTERY_READ (0x01 0x08) for params [1, 2, 3]
        let readReq = HuaweiPacket.readRequest(cmd: Data([0x01, 0x08]), parameterTypes: [1, 2, 3])
        do {
            if let resp = try await driver?.sendPackage(readReq, timeout: 2.0) {
                await onPackage(resp)
            }
        } catch {
            NSLog("[OFB-Battery] CMD_BATTERY_READ failed: %@", error.localizedDescription)
        }
    }

    public func onInit() async throws {
        await requestBatteryUpdate()
    }

    public func onPackage(_ package: HuaweiPacket) async {
        var out: [String: Any] = [:]
        let hexCmd = package.commandId.map { String(format: "%02X", $0) }.joined()

        NSLog("[OFB-Battery] Raw params for cmd %@: p1=%@, p2=%@, p3=%@",
              hexCmd,
              paramStr(package.parameters[1]),
              paramStr(package.parameters[2]),
              paramStr(package.parameters[3]))

        // Global battery percentage (param 1, single byte 1..100)
        if let param1 = package.parameters[1], param1.count == 1 {
            let val = Int(param1[0])
            if val > 0 && val <= 100 {
                out["global"] = val
            }
        }

        // TWS left, right, case battery levels (param 2, 3 bytes: [left, right, case])
        if let param2 = package.parameters[2], param2.count >= 2, withTws {
            let left = Int(param2[0])
            let right = Int(param2[1])
            if left >= 0 && left <= 100 { out["left"] = left }
            if right >= 0 && right <= 100 { out["right"] = right }
            if param2.count >= 3 {
                let caseBat = Int(param2[2])
                if caseBat > 0 && caseBat <= 100 { out["case"] = caseBat }
            }
        }

        // Charging status (param 3)
        if let param3 = package.parameters[3], !param3.isEmpty {
            let isCharging = param3.contains(0x01)
            out["is_charging"] = isCharging ? "true" : "false"
        }

        guard !out.isEmpty else {
            NSLog("[OFB-Battery] Ignoring empty battery update for cmd %@", hexCmd)
            return
        }

        NSLog("[OFB-Battery] Battery update received: %@", String(describing: out))
        // Use extendGroup: true so global, left, right, case are merged and preserved
        await driver?.putProperty(group: "battery", prop: nil, value: out, extendGroup: true)
    }
}

private func paramStr(_ data: Data?) -> String {
    guard let data = data else { return "nil" }
    let hex = data.map { String(format: "%02X", $0) }.joined(separator: " ")
    let dec = data.map { "\($0)" }.joined(separator: ",")
    return "Data(\(data.count)b) [hex: \(hex), dec: \(dec)]"
}

