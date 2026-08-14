// OFBCore/Driver/Models/PerModel/FreeBudsSE4Driver.swift

import Foundation

public final class FreeBudsSE4Driver: HuaweiDriver, @unchecked Sendable {
    public override init(address: String) {
        super.init(address: address)
        self.sppServicePort = 1
        self.handlers = [
            LogsHandler(),
            DeviceInfoHandler(),
            BatteryHandler(withTws: true),
            ANCHandler(withCancelLevel: true, withCancelDynamic: true, withVoiceBoost: false),
            DoubleTapHandler(wInCall: true),
            TripleTapHandler(),
            LongTapSplitHandler(wLeft: true, wRight: true, wInCall: false, wANC: true, wExtraOptions: true),
            EqualizerHandler(presets: [1: "default", 2: "hardbass", 3: "treble", 9: "voices"]),
            LowLatencyHandler()
        ]
    }
}
