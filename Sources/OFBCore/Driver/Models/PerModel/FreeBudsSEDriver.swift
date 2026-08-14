// OFBCore/Driver/Models/PerModel/FreeBudsSEDriver.swift

import Foundation

public final class FreeBudsSEDriver: HuaweiDriver, @unchecked Sendable {
    public override init(address: String) {
        super.init(address: address)
        self.sppServicePort = 16
        self.handlers = [
            LogsHandler(),
            DeviceInfoHandler(),
            BatteryHandler(withTws: true),
            DoubleTapHandler()
        ]
    }
}
