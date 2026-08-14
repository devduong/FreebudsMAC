// OFBCore/Driver/Models/PerModel/FreeBudsProDriver.swift

import Foundation

public final class FreeBudsProDriver: HuaweiDriver, @unchecked Sendable {
    public override init(address: String) {
        super.init(address: address)
        self.sppServicePort = 1
        self.handlers = [
            DeviceInfoHandler(),
            InEarStateHandler(),
            BatteryHandler(withTws: true),
            ANCHandler(withCancelLevel: true, withCancelDynamic: true, withVoiceBoost: true),
            SwipeGestureHandler(),
            LongTapSplitHandler(wLeft: true, wRight: true),
            VoiceLanguageHandler(),
            DualConnectHandler()
        ]
    }
}
