// OFBCore/Driver/Models/PerModel/FreeBuds5iDriver.swift

import Foundation

public final class FreeBuds5iDriver: HuaweiDriver, @unchecked Sendable {
    public override init(address: String) {
        super.init(address: address)
        self.sppServicePort = 16
        self.handlers = [
            DeviceInfoHandler(),
            InEarStateHandler(),
            BatteryHandler(withTws: true),
            ANCHandler(withCancelLevel: true, withCancelDynamic: true, withVoiceBoost: false),
            DoubleTapHandler(wInCall: true),
            TripleTapHandler(),
            LongTapSplitHandler(wLeft: true, wRight: true),
            SwipeGestureHandler(),
            AutoPauseHandler(),
            SoundQualityHandler(),
            LowLatencyHandler(),
            EqualizerHandler(presets: [1: "default", 2: "hardbass", 3: "treble", 9: "voices"]),
            VoiceLanguageHandler(),
            DualConnectHandler()
        ]
    }
}
