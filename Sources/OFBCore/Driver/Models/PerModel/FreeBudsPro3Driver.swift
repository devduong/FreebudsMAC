// OFBCore/Driver/Models/PerModel/FreeBudsPro3Driver.swift

import Foundation

public final class FreeBudsPro3Driver: HuaweiDriver, @unchecked Sendable {
    public override init(address: String) {
        super.init(address: address)
        self.sppServicePort = 1
        self.handlers = [
            // May work
            DeviceInfoHandler(),
            ANCHandler(withCancelLevel: true, withCancelDynamic: true, withVoiceBoost: true),
            BatteryHandler(withTws: true),
            SoundQualityHandler(),
            EqualizerHandler(presets: [5: "default", 1: "hardbass", 2: "treble", 9: "voice"]),
            AutoPauseHandler(),
            // Not tested, no research data
            DualConnectHandler(),
            InEarStateHandler(),
            VoiceLanguageHandler(),
            DoubleTapHandler(),
            LongTapSplitHandler(wLeft: true, wRight: true),
            SwipeGestureHandler(),
            LowLatencyHandler()
        ]
    }
}
