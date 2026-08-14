// OFBCore/Driver/Models/PerModel/FreeClip2Driver.swift

import Foundation

public final class FreeClip2Driver: HuaweiDriver, @unchecked Sendable {
    public override init(address: String) {
        super.init(address: address)
        self.sppServicePort = 1
        self.handlers = [
            // Confirmed working features
            DeviceInfoHandler(),
            BatteryHandler(withTws: true),
            AutoPauseHandler(),

            // Gesture handlers
            DoubleTapHandler(),
            TripleTapHandler(),
            LongTapSplitHandler(wLeft: true, wRight: false, wInCall: false, wANC: true, wExtraOptions: true),
            SwipeGestureHandler(),

            // Sound & audio quality
            EqualizerHandler(presets: [1: "default", 2: "hardbass", 3: "treble", 9: "voice"]),
            SoundQualityHandler(),
            LowLatencyHandler(),

            // Device features
            InEarStateHandler(),
            VoiceLanguageHandler(),
            DualConnectHandler()
        ]
    }
}
