// OFBCore/Handler/EqualizerHandler.swift

import Foundation

public final class EqualizerHandler: HuaweiHandler, @unchecked Sendable {
    public let handlerId: String = "config_eq"
    public let properties: [(group: String, prop: String)] = [
        ("sound", "equalizer_preset"),
        ("sound", "equalizer_rows"),
        ("sound", "equalizer_saved")
    ]
    public let commands: [Data] = [Data([0x2b, 0x4a])]
    public let ignoreCommands: [Data] = [Data([0x2b, 0x49])]

    public weak var driver: HuaweiDriver?

    public let withCustom: Bool
    public let withoutRead: Bool
    public let customRowsCount: Int
    public let maxCustomCount: Int
    public let withFakeBuiltIn: Bool

    public static let knownBuiltInPresets: [Int: String] = [
        1: "equalizer_preset_default",
        2: "equalizer_preset_hardbass",
        3: "equalizer_preset_treble",
        9: "equalizer_preset_voices"
    ]

    private var presetData: [(id: Int?, label: String, data: Data?)] = []
    private var defaultPresetData: [(id: Int?, label: String, data: Data?)] = []
    private var changesSaved: Bool = true

    public init(
        presets: [Int: String]? = nil,
        withCustom: Bool = false,
        withFakeBuiltIn: Bool = false,
        withoutRead: Bool = false,
        customRowsCount: Int = 10,
        maxCustomCount: Int = 3
    ) {
        self.withCustom = withCustom
        self.withoutRead = withoutRead
        self.customRowsCount = customRowsCount
        self.maxCustomCount = maxCustomCount
        self.withFakeBuiltIn = withFakeBuiltIn

        if let presets = presets {
            for (i, name) in presets {
                defaultPresetData.append((i, "equalizer_preset_\(name)", nil))
            }
        }
        self.presetData = defaultPresetData
    }

    public func onInit() async throws {
        if withoutRead {
            let labels = presetData.map { $0.label }.joined(separator: ",")
            await driver?.putProperty(group: "sound", prop: nil, value: [
                "equalizer_preset": "",
                "equalizer_preset_options": labels
            ], extendGroup: true)
            return
        }

        let readReq = HuaweiPacket.readRequest(cmd: Data([0x2b, 0x4a]), parameterTypes: [1, 2, 3, 4, 5, 6, 7, 8])
        if let resp = try await driver?.sendPackage(readReq) {
            await onPackage(resp)
        }
    }

    public func onPackage(_ package: HuaweiPacket) async {
        var newProps: [String: String] = [
            "equalizer_saved": changesSaved ? "true" : "false",
            "equalizer_rows_count": "\(customRowsCount)",
            "equalizer_max_custom_modes": withCustom ? "\(maxCustomCount)" : "0"
        ]

        presetData = defaultPresetData

        if let availableModes = package.parameters[3], !availableModes.isEmpty {
            for pId in availableModes {
                let name = Self.knownBuiltInPresets[Int(pId)] ?? "preset_\(pId)"
                presetData.append((Int(pId), name, nil))
            }
        }

        let optionsStr = presetData.map { $0.label }.joined(separator: ",")
        newProps["equalizer_preset_options"] = optionsStr

        if let currentMode = package.parameters[2], currentMode.count == 1 {
            let modeId = Int(Int8(bitPattern: currentMode[0]))
            var activeLabel = "unknown_\(modeId)"
            for (pId, label, data) in presetData {
                if pId == modeId {
                    activeLabel = label
                    if let d = data {
                        let rowsArray = d.map { Int(Int8(bitPattern: $0)) }
                        if let jsonData = try? JSONSerialization.data(withJSONObject: rowsArray),
                           let jsonStr = String(data: jsonData, encoding: .utf8) {
                            newProps["equalizer_rows"] = jsonStr
                        }
                    }
                    break
                }
            }
            newProps["equalizer_preset"] = activeLabel
        }

        await driver?.putProperty(group: "sound", prop: nil, value: newProps, extendGroup: true)
    }

    public func setProperty(group: String, prop: String, value: String) async throws {
        if prop == "equalizer_preset" {
            let pkg = HuaweiPacket.changeRequest(cmd: Data([0x2b, 0x49]), parameters: [(1, Data([1]))])
            _ = try await driver?.sendPackage(pkg)
            try await onInit()
        }
    }
}
