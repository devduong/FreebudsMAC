// OFBCore/Handler/GestureHandlers.swift

import Foundation

// MARK: - Double Tap Handler

public final class DoubleTapHandler: HuaweiHandler, @unchecked Sendable {
    public let handlerId: String = "action_double_tap"
    public let properties: [(group: String, prop: String)] = [
        ("action", "double_tap_left"),
        ("action", "double_tap_right"),
        ("action", "double_tap_in_call")
    ]

    // CMD_DUAL_TAP_READ = 0x0120, CMD_DUAL_TAP_WRITE = 0x011f
    private let cmdRead = Data([0x01, 0x20])
    private let cmdWrite = Data([0x01, 0x1f])

    public var commands: [Data] { [cmdRead, cmdWrite] }
    public let ignoreCommands: [Data] = []
    public weak var driver: HuaweiDriver?

    public let wInCall: Bool

    private let options: [Int8: String] = [
        -1: "tap_action_off",
         1: "tap_action_pause",
         2: "tap_action_next",
         7: "tap_action_prev",
         0: "tap_action_assistant"
    ]
    private let optionsCall: [Int8: String] = [
        -1: "tap_action_off",
         0: "tap_action_answer"
    ]

    public init(wInCall: Bool = false) {
        self.wInCall = wInCall
    }

    public func onInit() async throws {
        let readReq = HuaweiPacket.readRequest(cmd: cmdRead, parameterTypes: [1, 2])
        if let resp = try await driver?.sendPackage(readReq) {
            await onPackage(resp)
        }
    }

    public func onPackage(_ package: HuaweiPacket) async {
        guard package.commandId == cmdRead else { return }

        let left = package.findParam(1)
        let right = package.findParam(2)
        let inCall = package.findParam(4)
        let availableOptions = package.findParam(3)

        if left.count == 1 {
            let value = Int8(bitPattern: left[0])
            let str = options[value] ?? "\(value)"
            await driver?.putProperty(group: "action", prop: "double_tap_left", value: str, extendGroup: true)
        }
        if right.count == 1 {
            let value = Int8(bitPattern: right[0])
            let str = options[value] ?? "\(value)"
            await driver?.putProperty(group: "action", prop: "double_tap_right", value: str, extendGroup: true)
        }
        if availableOptions.count > 0 {
            let out = availableOptions.map { byte -> String in
                let signed = Int8(bitPattern: byte)
                return options[signed] ?? "\(signed)"
            }
            await driver?.putProperty(group: "action", prop: "double_tap_options", value: out.joined(separator: ","), extendGroup: true)
        }
        if inCall.count == 1 && wInCall {
            let value = Int8(bitPattern: inCall[0])
            let str = optionsCall[value] ?? "\(value)"
            await driver?.putProperty(group: "action", prop: "double_tap_in_call", value: str, extendGroup: true)
            await driver?.putProperty(group: "action", prop: "double_tap_in_call_options",
                                       value: optionsCall.values.joined(separator: ","), extendGroup: true)
        }
    }

    public func setProperty(group: String, prop: String, value: String) async throws {
        let pType: UInt8
        let pOptions: [Int8: String]

        if prop == "double_tap_left" {
            pType = 1
            pOptions = options
        } else if prop == "double_tap_right" {
            pType = 2
            pOptions = options
        } else if prop == "double_tap_in_call" {
            pType = 4
            pOptions = optionsCall
        } else {
            return
        }

        guard let byteVal = reverseDict(pOptions)[value] else { return }
        let pkg = HuaweiPacket.changeRequest(cmd: cmdWrite, parameters: [(pType, Data([UInt8(bitPattern: byteVal)]))])
        _ = try await driver?.sendPackage(pkg)
        await driver?.putProperty(group: group, prop: prop, value: value, extendGroup: true)
    }
}

// MARK: - Triple Tap Handler

public final class TripleTapHandler: HuaweiHandler, @unchecked Sendable {
    public let handlerId: String = "action_triple_tap"
    public let properties: [(group: String, prop: String)] = [
        ("action", "triple_tap_left"),
        ("action", "triple_tap_right"),
        ("action", "triple_tap_in_call")
    ]

    // CMD_TRIPLE_TAP_READ = 0x0126, CMD_TRIPLE_TAP_WRITE = 0x0125
    private let cmdRead = Data([0x01, 0x26])
    private let cmdWrite = Data([0x01, 0x25])

    public var commands: [Data] { [cmdRead, cmdWrite] }
    public let ignoreCommands: [Data] = []
    public weak var driver: HuaweiDriver?

    public let wInCall: Bool

    private let options: [Int8: String] = [
        -1: "tap_action_off",
         1: "tap_action_pause",
         2: "tap_action_next",
         7: "tap_action_prev",
         0: "tap_action_assistant"
    ]
    private let optionsCall: [Int8: String] = [
        -1: "tap_action_off",
         0: "tap_action_answer"
    ]

    public init(wInCall: Bool = false) {
        self.wInCall = wInCall
    }

    public func onInit() async throws {
        let readReq = HuaweiPacket.readRequest(cmd: cmdRead, parameterTypes: [1, 2])
        if let resp = try await driver?.sendPackage(readReq) {
            await onPackage(resp)
        }
    }

    public func onPackage(_ package: HuaweiPacket) async {
        guard package.commandId == cmdRead else { return }

        let left = package.findParam(1)
        let right = package.findParam(2)
        let inCall = package.findParam(4)
        let availableOptions = package.findParam(3)

        if left.count == 1 {
            let value = Int8(bitPattern: left[0])
            let str = options[value] ?? "\(value)"
            await driver?.putProperty(group: "action", prop: "triple_tap_left", value: str, extendGroup: true)
        }
        if right.count == 1 {
            let value = Int8(bitPattern: right[0])
            let str = options[value] ?? "\(value)"
            await driver?.putProperty(group: "action", prop: "triple_tap_right", value: str, extendGroup: true)
        }
        if availableOptions.count > 0 {
            let out = availableOptions.map { byte -> String in
                let signed = Int8(bitPattern: byte)
                return options[signed] ?? "\(signed)"
            }
            await driver?.putProperty(group: "action", prop: "triple_tap_options", value: out.joined(separator: ","), extendGroup: true)
        }
        if inCall.count == 1 && wInCall {
            let value = Int8(bitPattern: inCall[0])
            let str = optionsCall[value] ?? "\(value)"
            await driver?.putProperty(group: "action", prop: "triple_tap_in_call", value: str, extendGroup: true)
            await driver?.putProperty(group: "action", prop: "triple_tap_in_call_options",
                                       value: optionsCall.values.joined(separator: ","), extendGroup: true)
        }
    }

    public func setProperty(group: String, prop: String, value: String) async throws {
        let pType: UInt8
        let pOptions: [Int8: String]

        if prop == "triple_tap_left" {
            pType = 1
            pOptions = options
        } else if prop == "triple_tap_right" {
            pType = 2
            pOptions = options
        } else if prop == "triple_tap_in_call" {
            pType = 4
            pOptions = optionsCall
        } else {
            return
        }

        guard let byteVal = reverseDict(pOptions)[value] else { return }
        let pkg = HuaweiPacket.changeRequest(cmd: cmdWrite, parameters: [(pType, Data([UInt8(bitPattern: byteVal)]))])
        _ = try await driver?.sendPackage(pkg)
        await driver?.putProperty(group: group, prop: prop, value: value, extendGroup: true)
    }
}

// MARK: - Long Tap Handler (Non-split, e.g. FreeLace Pro)

public final class LongTapHandler: HuaweiHandler, @unchecked Sendable {
    public let handlerId: String = "action_long_tap"
    public let properties: [(group: String, prop: String)] = [
        ("action", "long_tap")
    ]

    // commands = [0x2b17], ignore_commands = [0x2b16]
    private let cmdRead = Data([0x2b, 0x17])
    private let cmdWrite = Data([0x2b, 0x16])

    public var commands: [Data] { [cmdRead] }
    public var ignoreCommands: [Data] { [cmdWrite] }
    public weak var driver: HuaweiDriver?

    private let options: [Int8: String] = [
        -1: "noise_control_disabled",
         3: "noise_control_off_on",
         5: "noise_control_off_on_aw",
         6: "noise_control_on_aw",
         9: "noise_control_off_an"
    ]

    public init() {}

    public func onInit() async throws {
        let readReq = HuaweiPacket.readRequest(cmd: cmdRead, parameterTypes: [1, 2])
        if let resp = try await driver?.sendPackage(readReq) {
            await onPackage(resp)
        }
    }

    public func onPackage(_ package: HuaweiPacket) async {
        let value = package.findParam(1)
        if value.count == 1 {
            let signed = Int8(bitPattern: value[0])
            let str = options[signed] ?? "\(signed)"
            await driver?.putProperty(group: "action", prop: "long_tap", value: str, extendGroup: true)
            await driver?.putProperty(group: "action", prop: "long_tap_options",
                                       value: options.values.joined(separator: ","), extendGroup: true)
        }
    }

    public func setProperty(group: String, prop: String, value: String) async throws {
        guard let byteVal = reverseDict(options)[value] else { return }
        let rawByte = UInt8(bitPattern: byteVal)
        let pkg = HuaweiPacket.changeRequest(cmd: cmdWrite, parameters: [
            (1, Data([rawByte])),
            (2, Data([rawByte]))
        ])
        let resp = try await driver?.sendPackage(pkg)
        if let respData = resp?.findParam(2), !respData.isEmpty, respData[0] == 0 {
            await driver?.putProperty(group: group, prop: prop, value: value, extendGroup: true)
        }
    }
}

// MARK: - Long Tap Split Handler

public final class LongTapSplitHandler: HuaweiHandler, @unchecked Sendable {
    public let handlerId: String = "action_long_tap_split"
    public let properties: [(group: String, prop: String)] = [
        ("action", "long_tap_left"),
        ("action", "long_tap_right"),
        ("action", "long_tap_in_call"),
        ("action", "noise_control_left"),
        ("action", "noise_control_right")
    ]

    // CMD_LONG_TAP_SPLIT_READ_BASE = 0x2b17
    // CMD_LONG_TAP_SPLIT_READ_ANC  = 0x2b19
    // CMD_LONG_TAP_SPLIT_WRITE_BASE = 0x2b16
    // CMD_LONG_TAP_SPLIT_WRITE_ANC  = 0x2b18
    private let cmdReadBase = Data([0x2b, 0x17])
    private let cmdReadANC = Data([0x2b, 0x19])
    private let cmdWriteBase = Data([0x2b, 0x16])
    private let cmdWriteANC = Data([0x2b, 0x18])

    public var commands: [Data] { [cmdReadBase, cmdReadANC, cmdWriteBase, cmdWriteANC] }
    public let ignoreCommands: [Data] = []
    public weak var driver: HuaweiDriver?

    public let wLeft: Bool
    public let wRight: Bool
    public let wInCall: Bool
    public let wANC: Bool

    private var optionsLT: [Int8: String]
    private let optionsLTCall: [Int8: String] = [
        -1: "tap_action_off",
         0: "tap_action_answer"
    ]
    private let optionsANC: [Int8: String] = [
        1: "noise_control_off_on",
        2: "noise_control_off_on_aw",
        3: "noise_control_on_aw",
        4: "noise_control_off_aw"
    ]

    public init(wLeft: Bool = true, wRight: Bool = false, wInCall: Bool = false, wANC: Bool = true, wExtraOptions: Bool = false) {
        self.wLeft = wLeft
        self.wRight = wRight
        self.wInCall = wInCall
        self.wANC = wANC

        var lt: [Int8: String] = [
            -1: "tap_action_off",
            10: "tap_action_switch_anc"
        ]
        if wExtraOptions {
            lt[0] = "tap_action_assistant"
            lt[18] = "tap_action_vol_up"
            lt[19] = "tap_action_vol_down"
        }
        self.optionsLT = lt
    }

    // Convenience init matching old API: LongTapSplitHandler(withRight: true)
    public convenience init(withRight: Bool = false) {
        self.init(wLeft: true, wRight: withRight)
    }

    public func onInit() async throws {
        // Base request
        let readBase = HuaweiPacket.readRequest(cmd: cmdReadBase, parameterTypes: [1, 2])
        if let resp = try await driver?.sendPackage(readBase) {
            await onPackage(resp)
        }

        // ANC options request
        if wANC {
            let readANC = HuaweiPacket.readRequest(cmd: cmdReadANC, parameterTypes: [1, 2])
            if let resp = try await driver?.sendPackage(readANC) {
                await onPackage(resp)
            }
        }
    }

    public func onPackage(_ package: HuaweiPacket) async {
        let left = package.findParam(1)
        let right = package.findParam(2)
        let inCall = package.findParam(4)

        if package.commandId == cmdReadBase {
            if left.count == 1 && wLeft {
                let value = Int8(bitPattern: left[0])
                let str = optionsLT[value] ?? "\(value)"
                await driver?.putProperty(group: "action", prop: "long_tap_left", value: str, extendGroup: true)
            }
            if right.count == 1 && wRight {
                let value = Int8(bitPattern: right[0])
                let str = optionsLT[value] ?? "\(value)"
                await driver?.putProperty(group: "action", prop: "long_tap_right", value: str, extendGroup: true)
            }
            if inCall.count == 1 && wInCall {
                let value = Int8(bitPattern: right.isEmpty ? inCall[0] : right[0])
                let str = optionsLTCall[value] ?? "\(value)"
                await driver?.putProperty(group: "action", prop: "long_tap_in_call", value: str, extendGroup: true)
                await driver?.putProperty(group: "action", prop: "long_tap_in_call_options",
                                           value: optionsLTCall.values.joined(separator: ","), extendGroup: true)
            }
            await driver?.putProperty(group: "action", prop: "long_tap_options",
                                       value: optionsLT.values.joined(separator: ","), extendGroup: true)
        } else if package.commandId == cmdReadANC {
            if left.count == 1 {
                let value = Int8(bitPattern: left[0])
                let str = optionsANC[value] ?? "\(value)"
                await driver?.putProperty(group: "action", prop: "noise_control_left", value: str, extendGroup: true)
            }
            if right.count == 1 && wRight {
                let value = Int8(bitPattern: right[0])
                let str = optionsANC[value] ?? "\(value)"
                await driver?.putProperty(group: "action", prop: "noise_control_right", value: str, extendGroup: true)
            }
            await driver?.putProperty(group: "action", prop: "noise_control_options",
                                       value: optionsANC.values.joined(separator: ","), extendGroup: true)
        }
    }

    public func setProperty(group: String, prop: String, value: String) async throws {
        let pType: UInt8
        let pOptions: [Int8: String]

        if prop.hasSuffix("_left") {
            pType = 1
            pOptions = prop.hasPrefix("long_tap") ? optionsLT : optionsANC
        } else if prop.hasSuffix("_right") {
            pType = 2
            pOptions = prop.hasPrefix("long_tap") ? optionsLT : optionsANC
        } else if prop.hasSuffix("_in_call") {
            pType = 4
            pOptions = optionsLTCall
        } else {
            return
        }

        guard let byteVal = reverseDict(pOptions)[value] else { return }

        let cmd: Data
        if prop.hasPrefix("long_tap") {
            cmd = cmdWriteBase
        } else {
            cmd = cmdWriteANC
        }

        let pkg = HuaweiPacket.changeRequest(cmd: cmd, parameters: [(pType, Data([UInt8(bitPattern: byteVal)]))])
        _ = try await driver?.sendPackage(pkg)
        await driver?.putProperty(group: group, prop: prop, value: value, extendGroup: true)
    }
}

// MARK: - Power Button Handler

public final class PowerButtonHandler: HuaweiHandler, @unchecked Sendable {
    public let handlerId: String = "action_power_button"
    public let properties: [(group: String, prop: String)] = [("action", "power_button")]

    // CMD_DUAL_TAP_READ = 0x0120, CMD_DUAL_TAP_WRITE = 0x011f
    private let cmdRead = Data([0x01, 0x20])
    private let cmdWrite = Data([0x01, 0x1f])

    public var commands: [Data] { [cmdRead, cmdWrite] }
    public let ignoreCommands: [Data] = []
    public weak var driver: HuaweiDriver?

    private let options: [Int8: String] = [
        -1: "tap_action_off",
        12: "tap_action_switch_device"
    ]

    public init() {}

    public func onInit() async throws {
        let readReq = HuaweiPacket.readRequest(cmd: cmdRead, parameterTypes: [1, 2])
        if let resp = try await driver?.sendPackage(readReq) {
            await onPackage(resp)
        }
    }

    public func onPackage(_ package: HuaweiPacket) async {
        guard package.commandId == cmdRead else { return }

        let action = package.findParam(1)
        if action.count == 1 {
            let value = Int8(bitPattern: action[0])
            let str = options[value] ?? "\(value)"
            await driver?.putProperty(group: "action", prop: "power_button", value: str, extendGroup: true)
        }
        await driver?.putProperty(group: "action", prop: "power_button_options",
                                   value: options.values.joined(separator: ","), extendGroup: true)
    }

    public func setProperty(group: String, prop: String, value: String) async throws {
        guard let byteVal = reverseDict(options)[value] else { return }
        let rawByte = UInt8(bitPattern: byteVal)
        let pkg = HuaweiPacket.changeRequest(cmd: cmdWrite, parameters: [
            (1, Data([rawByte])),
            (2, Data([rawByte]))
        ])
        _ = try await driver?.sendPackage(pkg)
        await driver?.putProperty(group: group, prop: prop, value: value, extendGroup: true)
    }
}

// MARK: - Swipe Gesture Handler

public final class SwipeGestureHandler: HuaweiHandler, @unchecked Sendable {
    public let handlerId: String = "action_swipe_gesture"
    public let properties: [(group: String, prop: String)] = [("action", "swipe_gesture")]

    // CMD_SWIPE_READ = 0x2b1f, CMD_SWIPE_WRITE = 0x2b1e
    private let cmdRead = Data([0x2b, 0x1f])
    private let cmdWrite = Data([0x2b, 0x1e])

    public var commands: [Data] { [cmdRead, cmdWrite] }
    public let ignoreCommands: [Data] = []
    public weak var driver: HuaweiDriver?

    private let options: [Int8: String] = [
        -1: "tap_action_off",
         0: "tap_action_change_volume"
    ]

    public init() {}

    public func onInit() async throws {
        let readReq = HuaweiPacket.readRequest(cmd: cmdRead, parameterTypes: [1, 2])
        if let resp = try await driver?.sendPackage(readReq) {
            await onPackage(resp)
        }
    }

    public func onPackage(_ package: HuaweiPacket) async {
        guard package.commandId == cmdRead else { return }

        let action = package.findParam(1)
        if action.count == 1 {
            let value = Int8(bitPattern: action[0])
            let str = options[value] ?? "\(value)"
            await driver?.putProperty(group: "action", prop: "swipe_gesture", value: str, extendGroup: true)
        }
        await driver?.putProperty(group: "action", prop: "swipe_gesture_options",
                                   value: options.values.joined(separator: ","), extendGroup: true)
    }

    public func setProperty(group: String, prop: String, value: String) async throws {
        guard let byteVal = reverseDict(options)[value] else { return }
        let rawByte = UInt8(bitPattern: byteVal)
        let pkg = HuaweiPacket.changeRequest(cmd: cmdWrite, parameters: [
            (1, Data([rawByte])),
            (2, Data([rawByte]))
        ])
        _ = try await driver?.sendPackage(pkg)
        await driver?.putProperty(group: group, prop: prop, value: value, extendGroup: true)
    }
}

// MARK: - Reverse Dict Utility

private func reverseDict(_ dict: [Int8: String]) -> [String: Int8] {
    var result: [String: Int8] = [:]
    for (k, v) in dict {
        result[v] = k
    }
    return result
}
