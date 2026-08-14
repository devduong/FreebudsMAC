// OFBCore/Driver/Models/PerModel/FreeLaceProDriver.swift

import Foundation

public final class FreeLaceProDriver: HuaweiDriver, @unchecked Sendable {
    public override init(address: String) {
        super.init(address: address)
        self.sppServicePort = 16
        self.sppConnectDelay = 2

        self.handlers = [
            DeviceInfoHandler(),
            BatteryHandler(withTws: false),
            ANCHandler(withCancelLevel: true, withCancelDynamic: false, withVoiceBoost: false),
            ANCLegacyHandler(),
            PowerButtonHandler(),
            LongTapHandler(),
            VoiceLanguageHandler()
        ]
    }
}
