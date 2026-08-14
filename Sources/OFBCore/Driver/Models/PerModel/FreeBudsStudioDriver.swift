// OFBCore/Driver/Models/PerModel/FreeBudsStudioDriver.swift

import Foundation

public final class FreeBudsStudioDriver: HuaweiDriver, @unchecked Sendable {
    public override init(address: String) {
        super.init(address: address)
        self.sppServicePort = 1
        self.handlers = [
            DeviceInfoHandler(),
            BatteryHandler(withTws: false),
            ANCHandler(withCancelLevel: true, withCancelDynamic: true, withVoiceBoost: true),
            AutoPauseHandler(),
            EqualizerHandler(presets: [1: "default", 2: "hardbass", 3: "treble"])
        ]
    }
}
