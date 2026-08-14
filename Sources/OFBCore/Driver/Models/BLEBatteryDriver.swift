// OFBCore/Driver/Models/BLEBatteryDriver.swift

import Foundation
import OFBBluetooth

/// Generic Fallback Driver for any non-HUAWEI / third-party Bluetooth TWS device outside of GenericHuaweiDriver.
/// Uses passive BLE scanning (Google Fast Pair Specification 0xFE2C & GATT Battery Service 0x180F)
/// to read and update Left, Right, Case battery levels without requiring SPP RFCOMM protocols.
public final class BLEBatteryDriver: BaseDriver, @unchecked Sendable {
    private let bleScanner = BLEBatteryScanner()

    public override init(address: String) {
        super.init(address: address)
    }

    /// BLE passive scan does not require a Bluetooth Classic connection.
    /// Always return true so mainloop proceeds to start the driver.
    public override func isDeviceOnline() async -> Bool {
        return true
    }

    /// BLE scanner is always healthy once started — no RFCOMM channel to break.
    public override func healthy() -> Bool {
        return started
    }

    public override func start() async throws {
        try await super.start()
        
        bleScanner.startScanning { [weak self] batteryInfo in
            guard let self = self else { return }
            Task {
                await self.putProperty(group: "battery", prop: nil, value: batteryInfo, extendGroup: true)
            }
        }
        NSLog("[OFB-BLEBatteryDriver] Started passive BLE battery scanner for device: %@", deviceAddress)
    }

    public override func stop() async {
        bleScanner.stopScanning()
        await super.stop()
        NSLog("[OFB-BLEBatteryDriver] Stopped passive BLE battery scanner for device: %@", deviceAddress)
    }

    public func requestBatteryUpdate() async {
        bleScanner.startScanning()
    }
}
