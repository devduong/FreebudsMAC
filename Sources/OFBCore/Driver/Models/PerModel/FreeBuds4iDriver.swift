// OFBCore/Driver/Models/PerModel/FreeBuds4iDriver.swift

import Foundation

public final class FreeBuds4iDriver: HuaweiDriver, @unchecked Sendable {
    public override init(address: String) {
        super.init(address: address)
        self.sppServicePort = 16
        self.handlers = [
            LogsHandler(),
            DeviceInfoHandler(),
            InEarStateHandler(),
            ANCHandler(withCancelLevel: false, withCancelDynamic: false, withVoiceBoost: false),
            BatteryHandler(withTws: true),
            DoubleTapHandler(),
            LongTapSplitHandler(),
            AutoPauseHandler(),
            VoiceLanguageHandler()
        ]
    }
}
