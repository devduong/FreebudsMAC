// OFBCore/Driver/Models/PerModel/FreeBudsPro2Driver.swift

import Foundation

public final class FreeBudsPro2Driver: HuaweiDriver, @unchecked Sendable {
    public override init(address: String) {
        super.init(address: address)
        self.sppServicePort = 1
        self.handlers = [
            DeviceInfoHandler(),
            InEarStateHandler(),
            BatteryHandler(withTws: true),
            ANCHandler(withCancelLevel: true, withCancelDynamic: false, withVoiceBoost: false),
            LongTapSplitHandler(wLeft: true, wRight: true),
            SwipeGestureHandler(),
            AutoPauseHandler(),
            SoundQualityHandler(),
            EqualizerHandler(presets: [1: "default", 2: "hardbass", 3: "treble"]),
            DualConnectHandler(),
            VoiceLanguageHandler()
        ]
    }
}
