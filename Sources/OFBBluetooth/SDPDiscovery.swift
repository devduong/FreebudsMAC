// OFBBluetooth/SDPDiscovery.swift

@preconcurrency import Foundation
@preconcurrency import IOBluetooth

// MARK: - Async SDP Query Helper

/// NSObject subclass that receives `sdpQueryComplete:status:` from IOBluetooth.
/// Stored as a static reference to prevent premature deallocation.
final class SDPQueryCallbackTarget: NSObject, @unchecked Sendable {
    private var continuation: CheckedContinuation<Void, Error>?
    private let lock = NSLock()
    
    // Static reference to keep the target alive until callback fires
    private static var activeTargets: [ObjectIdentifier: SDPQueryCallbackTarget] = [:]
    private static let targetsLock = NSLock()

    init(continuation: CheckedContinuation<Void, Error>) {
        self.continuation = continuation
        super.init()
        // Prevent deallocation
        _ = Self.targetsLock.withLock {
            Self.activeTargets[ObjectIdentifier(self)] = self
        }
    }

    @objc func sdpQueryComplete(_ device: IOBluetoothDevice!, status: IOReturn) {
        finish(status: status)
    }

    func finish(status: IOReturn = kIOReturnSuccess) {
        lock.withLock {
            guard let cont = continuation else { return }
            continuation = nil
            _ = Self.targetsLock.withLock {
                Self.activeTargets.removeValue(forKey: ObjectIdentifier(self))
            }
            if status == kIOReturnSuccess {
                cont.resume()
            } else {
                cont.resume(throwing: NSError(domain: "SDPDiscovery", code: Int(status), userInfo: [
                    NSLocalizedDescriptionKey: "SDP query failed with status \(status)"
                ]))
            }
        }
    }

    func timeout() {
        lock.withLock {
            guard let cont = continuation else { return }
            continuation = nil
            _ = Self.targetsLock.withLock {
                Self.activeTargets.removeValue(forKey: ObjectIdentifier(self))
            }
            // On timeout, resume successfully - we'll try with whatever services are available
            cont.resume()
        }
    }
}

public enum SDPDiscovery {

    // SDP type codes (Bluetooth Core spec, Vol 3 Part B)
    private static let sdpTypeUint: UInt8 = 1
    private static let sdpTypeUuid: UInt8 = 3
    private static let sdpTypeSeq: UInt8  = 6
    private static let sdpTypeAlt: UInt8  = 7

    // Well-known SDP UUIDs (16-bit short form)
    private static let uuidRfcomm: UInt16 = 0x0003
    private static let uuidSpp: UInt16    = 0x1101

    // SDP attribute IDs
    private static let attrServiceClassIDList: BluetoothSDPServiceAttributeID = 0x0001
    private static let attrProtocolDescriptorList: BluetoothSDPServiceAttributeID = 0x0004

    private static let btBaseUUIDTail = Data([0x00, 0x00, 0x10, 0x00, 0x80, 0x00, 0x00, 0x80, 0x5F, 0x9B, 0x34, 0xFB])

    // MARK: - Async SDP Query

    /// Perform an SDP query on the device and wait for completion (with timeout).
    /// Runs on IOBluetoothThread (background thread with RunLoop).
    public static func performQueryAsync(device: IOBluetoothDevice, timeout: TimeInterval = 4) async {
        // If services are already cached, skip query
        if let services = device.services as? [IOBluetoothSDPServiceRecord], !services.isEmpty {
            NSLog("[OFB-SDP] Services already cached (%d services), skipping SDP query", services.count)
            return
        }

        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                IOBluetoothThread.shared.performAsync {
                    let target = SDPQueryCallbackTarget(continuation: continuation)
                    let status = device.performSDPQuery(target)
                    
                    if status != kIOReturnSuccess {
                        NSLog("[OFB-SDP] performSDPQuery returned error %d, proceeding with fallback", status)
                        target.finish(status: kIOReturnSuccess)
                        return
                    }
                    
                    NSLog("[OFB-SDP] SDP query started on BT thread, waiting for callback (timeout %.0fs)...", timeout)
                    
                    // Timeout on a different queue to not block the BT thread RunLoop
                    DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                        target.timeout()
                    }
                }
            }
        } catch {
            NSLog("[OFB-SDP] SDP query error: %@, proceeding with fallback", error.localizedDescription)
        }

        let serviceCount = (device.services as? [IOBluetoothSDPServiceRecord])?.count ?? 0
        NSLog("[OFB-SDP] SDP query complete, found %d services", serviceCount)
    }

    // MARK: - Helper Decoders

    private static func getSeqElements(_ elem: IOBluetoothSDPDataElement) -> [IOBluetoothSDPDataElement] {
        let td = elem.getTypeDescriptor()
        if td != sdpTypeSeq && td != sdpTypeAlt {
            return []
        }
        guard let arr = elem.getArrayValue() as? [IOBluetoothSDPDataElement] else {
            return []
        }
        return arr
    }

    private static func getUintValue(_ elem: IOBluetoothSDPDataElement) -> Int? {
        guard elem.getTypeDescriptor() == sdpTypeUint else { return nil }
        guard let num = elem.getNumberValue() else { return nil }
        return num.intValue
    }

    private static func getUUID16Value(_ elem: IOBluetoothSDPDataElement) -> UInt16? {
        guard elem.getTypeDescriptor() == sdpTypeUuid else { return nil }
        guard let uuidObj = elem.getUUIDValue() else { return nil }

        guard uuidObj.length > 0 else {
            return nil
        }
        let bytesPtr = uuidObj.bytes
        let data = Data(bytes: bytesPtr, count: Int(uuidObj.length))

        if data.count == 2 {
            return UInt16(data[0]) << 8 | UInt16(data[1])
        }
        if data.count == 4 {
            let b0 = UInt32(data[0]) << 24
            let b1 = UInt32(data[1]) << 16
            let b2 = UInt32(data[2]) << 8
            let b3 = UInt32(data[3])
            let v = b0 | b1 | b2 | b3
            return (v >> 16 == 0) ? UInt16(v & 0xFFFF) : nil
        }
        if data.count == 16 && data.suffix(12) == btBaseUUIDTail {
            let b0 = UInt32(data[0]) << 24
            let b1 = UInt32(data[1]) << 16
            let b2 = UInt32(data[2]) << 8
            let b3 = UInt32(data[3])
            let v = b0 | b1 | b2 | b3
            return UInt16(v & 0xFFFF)
        }
        return nil
    }

    // MARK: - Service Parsers

    private static func extractRFCOMMChannel(serviceRecord: IOBluetoothSDPServiceRecord) -> Int? {
        guard let attributes = serviceRecord.attributes as? [NSNumber: IOBluetoothSDPDataElement] else {
            return nil
        }

        guard let pdl = attributes[NSNumber(value: attrProtocolDescriptorList)] else {
            return nil
        }

        for protocolEntry in getSeqElements(pdl) {
            let items = getSeqElements(protocolEntry)
            if items.count >= 2 {
                if getUUID16Value(items[0]) == uuidRfcomm {
                    return getUintValue(items[1])
                }
            }
        }
        return nil
    }

    private static func extractServiceClassUUIDs(serviceRecord: IOBluetoothSDPServiceRecord) -> [UInt16] {
        guard let attributes = serviceRecord.attributes as? [NSNumber: IOBluetoothSDPDataElement] else {
            return []
        }
        guard let scl = attributes[NSNumber(value: attrServiceClassIDList)] else {
            return []
        }

        var uuids: [UInt16] = []
        for entry in getSeqElements(scl) {
            if let u = getUUID16Value(entry) {
                uuids.append(u)
            }
        }
        return uuids
    }

    // MARK: - Public API

    public static func findSPPChannel(device: IOBluetoothDevice, fallback: Int? = nil) -> Int? {
        guard let services = device.services as? [IOBluetoothSDPServiceRecord], !services.isEmpty else {
            NSLog("[OFB-SDP] No SDP services found on device")
            return nil
        }

        struct Candidate {
            let channel: Int
            let name: String?
            let uuids: [UInt16]
        }

        var candidates: [Candidate] = []
        for svc in services {
            if let ch = extractRFCOMMChannel(serviceRecord: svc) {
                let name = svc.getServiceName()
                let uuids = extractServiceClassUUIDs(serviceRecord: svc)
                candidates.append(Candidate(channel: ch, name: name, uuids: uuids))
                NSLog("[OFB-SDP]   RFCOMM candidate: ch=%d name=%@ uuids=%@", ch, name ?? "(nil)", uuids.map { String(format: "0x%04X", $0) }.joined(separator: ","))
            }
        }

        if candidates.isEmpty {
            NSLog("[OFB-SDP] No RFCOMM candidates found in %d services", services.count)
            return nil
        }

        for cand in candidates {
            if cand.uuids.contains(uuidSpp) {
                NSLog("[OFB-SDP] Found SPP service on channel %d", cand.channel)
                return cand.channel
            }
        }

        if let fallback = fallback {
            for cand in candidates {
                if cand.channel == fallback {
                    NSLog("[OFB-SDP] Using fallback channel %d", cand.channel)
                    return cand.channel
                }
            }
        }

        for cand in candidates {
            if let name = cand.name, name.lowercased().contains("serial") {
                NSLog("[OFB-SDP] Using serial-named service on channel %d", cand.channel)
                return cand.channel
            }
        }

        // Last resort: return the first candidate
        let first = candidates[0].channel
        NSLog("[OFB-SDP] Using first available RFCOMM channel %d", first)
        return first
    }

    public static func findAllRFCOMMChannels(device: IOBluetoothDevice, fallback: Int? = 16) -> [Int] {
        var channels: [Int] = []
        if let primary = findSPPChannel(device: device, fallback: fallback) {
            channels.append(primary)
        }
        if let services = device.services as? [IOBluetoothSDPServiceRecord] {
            for svc in services {
                if let ch = extractRFCOMMChannel(serviceRecord: svc), !channels.contains(ch) {
                    channels.append(ch)
                }
            }
        }
        if let fallback = fallback, !channels.contains(fallback) {
            channels.append(fallback)
        }
        // Multi-channel fallback: Always include common candidate channels (16, 18, 2, 24, 1, 4)
        // to handle driver channel 16 blocking (error -536870212).
        let standardCandidates = [16, 18, 2, 24, 1, 4]
        for ch in standardCandidates {
            if !channels.contains(ch) {
                channels.append(ch)
            }
        }
        return channels
    }
}

