// OFBCore/Driver/Models/VirtualDeviceDriver.swift

import Foundation

public final class VirtualDeviceDriver: HuaweiDriver, @unchecked Sendable {
    public override init(address: String = "00:11:22:33:44:55") {
        super.init(address: address)
        self.sppServicePort = 1
        self.handlers = [
            DeviceInfoHandler(),
            ANCHandler(withCancelLevel: true, withCancelDynamic: true, withVoiceBoost: true),
            BatteryHandler(withTws: true),
            SoundQualityHandler(),
            EqualizerHandler(presets: [5: "default", 1: "hardbass", 2: "treble", 9: "voice"], withCustom: true),
            AutoPauseHandler(),
            DualConnectHandler(),
            InEarStateHandler(),
            VoiceLanguageHandler(),
            DoubleTapHandler(),
            TripleTapHandler(),
            LongTapSplitHandler(withRight: true),
            SwipeGestureHandler(),
            LowLatencyHandler()
        ]
    }

    public override func isDeviceOnline() async -> Bool {
        return true
    }

    public override func start() async throws {
        try await super.start()
        // Initialize default virtual properties for UI testing
        await putProperty(group: "info", prop: nil, value: [
            "device_name": "HUAWEI FreeBuds Pro 3 (Virtual)",
            "firmware_version": "3.0.0.188",
            "serial_number": "VIRTUAL123456789"
        ], extendGroup: false)

        await putProperty(group: "battery", prop: nil, value: [
            "global": 95,
            "left": 90,
            "right": 85,
            "case": 100,
            "is_charging": "false"
        ], extendGroup: false)

        await putProperty(group: "anc", prop: nil, value: [
            "mode": "normal",
            "mode_options": "normal,cancellation,awareness",
            "level": "normal",
            "level_options": "comfort,normal,ultra,dynamic"
        ], extendGroup: false)

        await putProperty(group: "sound", prop: nil, value: [
            "quality_preference": "sqp_quality",
            "equalizer_preset": "equalizer_preset_default",
            "equalizer_preset_options": "equalizer_preset_default,equalizer_preset_hardbass,equalizer_preset_treble,equalizer_preset_voices",
            "equalizer_rows": "[0,0,0,0,0,0,0,0,0,0]",
            "equalizer_saved": "true",
            "equalizer_max_custom_modes": "3"
        ], extendGroup: false)

        await putProperty(group: "action", prop: nil, value: [
            "double_tap_left": "tap_action_pause",
            "double_tap_right": "tap_action_pause",
            "triple_tap_left": "tap_action_next",
            "triple_tap_right": "tap_action_prev",
            "long_tap_left": "tap_action_switch_anc",
            "long_tap_right": "tap_action_switch_anc",
            "swipe_gesture": "tap_action_change_volume"
        ], extendGroup: false)

        await putProperty(group: "state", prop: nil, value: [
            "in_ear_left": "true",
            "in_ear_right": "true"
        ], extendGroup: false)

        await putProperty(group: "config", prop: nil, value: [
            "auto_pause": "true",
            "low_latency": "false",
            "voice_language": "1"
        ], extendGroup: false)

        await putProperty(group: "dual_connect", prop: nil, value: [
            "enabled": "true",
            "preferred_device": "001122334455"
        ], extendGroup: false)
    }

    public override func loopRecv(stream: AsyncStream<Data>) async {
        // Virtual driver doesn't read real RFCOMM stream
    }

    public override func writeData(_ data: Data) async throws {
        // Virtual driver accepts written bytes silently
    }
}
