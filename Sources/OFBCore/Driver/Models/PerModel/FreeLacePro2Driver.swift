// OFBCore/Driver/Models/PerModel/FreeLacePro2Driver.swift

import Foundation

public final class FreeLacePro2Driver: HuaweiDriver, @unchecked Sendable {
    public override init(address: String) {
        super.init(address: address)
        self.sppServicePort = 1
        self.handlers = [
            DeviceInfoHandler(),
            BatteryHandler(withTws: false),
            ANCHandler(withCancelLevel: true, withCancelDynamic: true, withVoiceBoost: true),
            LongTapSplitHandler(),
            VoiceLanguageHandler(),
            EqualizerHandler(presets: [1: "default", 2: "hardbass", 3: "treble"]),
            SoundQualityHandler(),
            LowLatencyHandler(),
            DualConnectHandler()
        ]
    }
}
