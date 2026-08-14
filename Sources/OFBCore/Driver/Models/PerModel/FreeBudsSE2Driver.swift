// OFBCore/Driver/Models/PerModel/FreeBudsSE2Driver.swift

import Foundation

public final class FreeBudsSE2Driver: HuaweiDriver, @unchecked Sendable {
    public override init(address: String) {
        super.init(address: address)
        self.sppServicePort = 1
        self.handlers = [
            LogsHandler(),
            DeviceInfoHandler(),
            BatteryHandler(withTws: true),
            DoubleTapHandler(wInCall: true),
            TripleTapHandler(),
            LongTapSplitHandler(wLeft: false, wRight: false, wInCall: true, wANC: false),
            EqualizerHandler(presets: [1: "default", 2: "hardbass", 3: "treble", 9: "voices"]),
            LowLatencyHandler()
        ]
    }
}
