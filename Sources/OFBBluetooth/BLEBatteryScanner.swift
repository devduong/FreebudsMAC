import Foundation
import CoreBluetooth

/// Passive BLE Battery Scanner for Google Fast Pair Specification (GFPS - Service UUID 0xFE2C)
/// & Standard BLE Battery Service (GATT 0x180F).
/// Designed to parse Left, Right, Case battery levels for third-party TWS earphones.
public final class BLEBatteryScanner: NSObject, CBCentralManagerDelegate, @unchecked Sendable {
    private var centralManager: CBCentralManager?
    private var isScanning = false
    private let scannerQueue = DispatchQueue(label: "pw.mmk.OpenFreebuds.BLEScanner", qos: .utility)
    
    public var onBatteryUpdated: (@Sendable ([String: Any]) -> Void)?

    public override init() {
        super.init()
    }

    /// Start passive scanning filtered for Fast Pair Service 0xFE2C
    public func startScanning(onBatteryUpdated: (@Sendable ([String: Any]) -> Void)? = nil) {
        if let callback = onBatteryUpdated {
            self.onBatteryUpdated = callback
        }
        
        scannerQueue.async { [weak self] in
            guard let self = self else { return }
            if self.centralManager == nil {
                self.centralManager = CBCentralManager(delegate: self, queue: self.scannerQueue)
            } else if self.centralManager?.state == .poweredOn && !self.isScanning {
                self.performScan()
            }
        }
    }

    /// Stop scanning immediately to save 100% CPU and Bluetooth bandwidth
    public func stopScanning() {
        scannerQueue.async { [weak self] in
            guard let self = self, self.isScanning else { return }
            self.centralManager?.stopScan()
            self.isScanning = false
            NSLog("[OFB-BLEScanner] ⏹ Scanner stopped")
        }
    }

    private func performScan() {
        guard let cm = centralManager, cm.state == .poweredOn else { return }
        
        cm.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
        isScanning = true
        NSLog("[OFB-BLEScanner] ▶️ Passive BLE Scanner started (FastPair 0xFE2C / GATT 0x180F)")
    }

    // MARK: - CBCentralManagerDelegate

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn && isScanning == false && onBatteryUpdated != nil {
            performScan()
        }
    }

    public func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let fastPairUUID = CBUUID(string: "FE2C")
        let batteryServiceUUID = CBUUID(string: "180F")
        
        if let serviceDataDict = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data] {
            // 1. Primary: Parse Google Fast Pair Service Data (0xFE2C - Left / Right / Case TWS)
            if let gfpsData = serviceDataDict[fastPairUUID] {
                parseFastPairBattery(gfpsData, peripheralName: peripheral.name ?? "Unknown")
            }
            // 2. Fallback: Parse Standard BLE Battery Service Data (0x180F - Global Battery %)
            else if let batteryData = serviceDataDict[batteryServiceUUID], let pct = batteryData.first, pct <= 100 {
                let batteryInfo: [String: Any] = ["global": Int(pct)]
                NSLog("[OFB-BLEScanner] 🔋 GATT Battery (0x180F) discovered for %@: %d%%", peripheral.name ?? "Unknown", pct)
                onBatteryUpdated?(batteryInfo)
            }
        }
    }

    /// Parse Google Fast Pair Specification Battery Data Payload
    private func parseFastPairBattery(_ data: Data, peripheralName: String) {
        guard data.count >= 3 else { return }
        
        var batteryInfo: [String: Any] = [:]
        
        // Byte 0: Left Earbud (Bit 7: Charging, Bits 0..6: % Battery)
        let leftRaw = data[0]
        let leftVal = Int(leftRaw & 0x7F)
        let leftCharging = (leftRaw & 0x80) != 0
        if leftVal >= 0 && leftVal <= 100 {
            batteryInfo["left"] = leftVal
        }
        
        // Byte 1: Right Earbud (Bit 7: Charging, Bits 0..6: % Battery)
        let rightRaw = data[1]
        let rightVal = Int(rightRaw & 0x7F)
        let rightCharging = (rightRaw & 0x80) != 0
        if rightVal >= 0 && rightVal <= 100 {
            batteryInfo["right"] = rightVal
        }
        
        // Byte 2: Charging Case (Bit 7: Charging, Bits 0..6: % Battery)
        let caseRaw = data[2]
        let caseVal = Int(caseRaw & 0x7F)
        let caseCharging = (caseRaw & 0x80) != 0
        if caseVal >= 0 && caseVal <= 100 {
            batteryInfo["case"] = caseVal
        }
        
        if leftCharging || rightCharging || caseCharging {
            batteryInfo["is_charging"] = "true"
        } else {
            batteryInfo["is_charging"] = "false"
        }
        
        guard !batteryInfo.isEmpty else { return }
        
        NSLog("[OFB-BLEScanner] 🔋 FastPair Battery discovered for %@: %@", peripheralName, String(describing: batteryInfo))
        onBatteryUpdated?(batteryInfo)
    }
}
