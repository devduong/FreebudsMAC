// OFBBluetooth/RFCOMMTransport.swift
//
// All IOBluetooth operations run on IOBluetoothThread (background thread
// with its own NSRunLoop) so the main/UI thread is never blocked.

@preconcurrency import Foundation
@preconcurrency import IOBluetooth

// MARK: - Logging Helper

private func rfLog(_ message: String) {
    NSLog("[OFB-RFCOMM] %@", message)
}

// MARK: - Delegate

final class RFCOMMDelegate: NSObject, IOBluetoothRFCOMMChannelDelegate, @unchecked Sendable {
    private let onOpenComplete: (IOReturn) -> Void
    private let onDataReceived: (Data) -> Void
    private let onClosed: (IOBluetoothRFCOMMChannel?) -> Void
    private let onWriteComplete: (UInt, IOReturn) -> Void

    init(
        onOpenComplete: @escaping (IOReturn) -> Void,
        onDataReceived: @escaping (Data) -> Void,
        onClosed: @escaping (IOBluetoothRFCOMMChannel?) -> Void,
        onWriteComplete: @escaping (UInt, IOReturn) -> Void
    ) {
        self.onOpenComplete = onOpenComplete
        self.onDataReceived = onDataReceived
        self.onClosed = onClosed
        self.onWriteComplete = onWriteComplete
        super.init()
    }

    @objc func rfcommChannelOpenComplete(_ channel: IOBluetoothRFCOMMChannel!, status error: IOReturn) {
        rfLog("delegate: rfcommChannelOpenComplete status=\(error)")
        onOpenComplete(error)
    }

    @objc func rfcommChannelData(_ channel: IOBluetoothRFCOMMChannel!, data dataPointer: UnsafeMutableRawPointer!, length: Int) {
        guard length > 0, let dataPointer = dataPointer else { return }
        let data = Data(bytes: dataPointer, count: length)
        onDataReceived(data)
    }

    @objc func rfcommChannelClosed(_ channel: IOBluetoothRFCOMMChannel!) {
        rfLog("delegate: rfcommChannelClosed for channel \(channel?.getID() ?? 0)")
        onClosed(channel)
    }

    @objc func rfcommChannelWriteComplete(_ channel: IOBluetoothRFCOMMChannel!, refcon: UnsafeMutableRawPointer!, status error: IOReturn) {
        let ref = UInt(bitPattern: refcon)
        onWriteComplete(ref, error)
    }
}

// MARK: - Errors

public enum RFCOMMError: Error, CustomStringErrorConvertible {
    case deviceNotFound(String)
    case openConnectionFailed(IOReturn)
    case openChannelFailed(IOReturn)
    case channelOpenTimeout
    case channelClosed
    case writeFailed(IOReturn)

    public var description: String {
        switch self {
        case .deviceNotFound(let addr): return "Bluetooth device not found: \(addr)"
        case .openConnectionFailed(let err): return "openConnection failed with status \(err)"
        case .openChannelFailed(let err): return "openRFCOMMChannelSync failed with status \(err)"
        case .channelOpenTimeout: return "RFCOMM channel open timed out"
        case .channelClosed: return "RFCOMM channel was closed"
        case .writeFailed(let err): return "RFCOMM write failed with status \(err)"
        }
    }
}

public protocol CustomStringErrorConvertible: LocalizedError {
    var description: String { get }
}

extension CustomStringErrorConvertible {
    public var errorDescription: String? { description }
}

// MARK: - RFCOMMTransport

public final class RFCOMMTransport: @unchecked Sendable {
    private var channel: IOBluetoothRFCOMMChannel?
    private var delegate: RFCOMMDelegate?
    private var nextRefcon: UInt = 1
    private var writeContinuations: [UInt: CheckedContinuation<Void, Error>] = [:]
    private let continuationsLock = NSLock()
    private(set) public var isOpen: Bool = false

    private var dataContinuation: AsyncStream<Data>.Continuation?

    public init() {}

    deinit {
        close()
    }

    // MARK: - Open

    /// Opens an RFCOMM channel to the device.
    ///
    /// All IOBluetooth calls run on IOBluetoothThread (dedicated background
    /// thread with RunLoop) so the main/UI thread is never blocked.
    public func open(
        address: String,
        channel channelID: Int,
        connectDelay: TimeInterval = 0
    ) async throws -> AsyncStream<Data> {
        rfLog("open() called: address=\(address), channelID=\(channelID)")

        let btManager = BluetoothManager.shared
        guard let device = btManager.findDevice(address: address) else {
            rfLog("❌ Device not found for address: \(address)")
            throw RFCOMMError.deviceNotFound(address)
        }

        rfLog("Found device: \(device.name ?? "?") (isConnected: \(device.isConnected()))")

        // 1. Ensure Bluetooth baseband connection is open
        if !device.isConnected() {
            rfLog("Device not connected to macOS, calling openConnection on background thread...")
            let openErr: IOReturn = await withCheckedContinuation { cont in
                DispatchQueue.global(qos: .userInitiated).async {
                    let err = device.openConnection()
                    cont.resume(returning: err)
                }
            }
            if openErr != kIOReturnSuccess {
                rfLog("❌ openConnection failed: \(openErr)")
                throw RFCOMMError.openConnectionFailed(openErr)
            }
            rfLog("openConnection succeeded, waiting 1s...")
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }

        // 2. Perform SDP query (best-effort, on BT thread)
        rfLog("Starting SDP query...")
        await SDPDiscovery.performQueryAsync(device: device, timeout: 4)

        let resolvedChannel = SDPDiscovery.findSPPChannel(device: device, fallback: channelID) ?? channelID
        rfLog("Resolved RFCOMM channel: \(resolvedChannel) (fallback was: \(channelID))")

        if connectDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(connectDelay * 1_000_000_000))
        }

        let (stream, continuation) = AsyncStream<Data>.makeStream()
        self.dataContinuation = continuation

        // 3. Open RFCOMM channel on IOBluetoothThread
        rfLog("Opening RFCOMM channel \(resolvedChannel) on IOBluetoothThread...")

        return try await withCheckedThrowingContinuation { (openCont: CheckedContinuation<AsyncStream<Data>, Error>) in
            let contBox = ContinuationBox(openCont)

            IOBluetoothThread.shared.performAsync { [weak self] in
                guard let self = self else {
                    contBox.resume(throwing: RFCOMMError.channelClosed)
                    return
                }

                let candidateChannels = SDPDiscovery.findAllRFCOMMChannels(device: device, fallback: channelID)
                rfLog("Candidate RFCOMM channels to try: \(candidateChannels)")

                var openSuccess = false
                var lastOpenErr: IOReturn = kIOReturnError

                for ch in candidateChannels {
                    rfLog("Attempting openRFCOMMChannelSync on channel \(ch)...")

                    let delegate = RFCOMMDelegate(
                        onOpenComplete: { status in
                            rfLog("Channel \(ch) openComplete callback status: \(status)")
                        },
                        onDataReceived: { [weak self] data in
                            self?.dataContinuation?.yield(data)
                        },
                        onClosed: { [weak self] closedChannel in
                            guard let self = self else { return }
                            guard let currentChannel = self.channel, let closedChannel = closedChannel, closedChannel == currentChannel else {
                                rfLog("Ignoring closed callback for non-active or nil channel")
                                return
                            }
                            rfLog("Active RFCOMM channel \(currentChannel.getID()) closed by remote")
                            self.isOpen = false
                            self.dataContinuation?.finish()
                            self.failAllPendingWrites(with: RFCOMMError.channelClosed)
                        },
                        onWriteComplete: { [weak self] ref, status in
                            self?.handleWriteComplete(ref: ref, status: status)
                        }
                    )

                    var rfcommChannel: IOBluetoothRFCOMMChannel?
                    let openErr = device.openRFCOMMChannelSync(
                        &rfcommChannel,
                        withChannelID: BluetoothRFCOMMChannelID(ch),
                        delegate: delegate
                    )

                    rfLog("openRFCOMMChannelSync channel \(ch) returned: \(openErr) (0 = success)")
                    if openErr == kIOReturnSuccess, let channelObj = rfcommChannel {
                        self.delegate = delegate
                        self.channel = channelObj
                        self.isOpen = true
                        openSuccess = true
                        lastOpenErr = kIOReturnSuccess
                        rfLog("✅ Successfully opened RFCOMM channel \(channelObj.getID())")
                        break
                    } else {
                        lastOpenErr = openErr
                    }
                }

                if openSuccess {
                    contBox.resume(returning: stream)
                } else {
                    rfLog("❌ openRFCOMMChannelSync failed on all candidate channels, last error: \(lastOpenErr)")
                    self.delegate = nil
                    self.isOpen = false
                    contBox.resume(throwing: RFCOMMError.openChannelFailed(lastOpenErr))
                }
            }
        }
    }

    // MARK: - Write

    public func write(_ data: Data) async throws {
        guard isOpen, let channel = channel else {
            throw RFCOMMError.channelClosed
        }

        let ref: UInt = continuationsLock.withLock {
            let r = nextRefcon
            nextRefcon += 1
            return r
        }

        let refPointer = UnsafeMutableRawPointer(bitPattern: ref)

        try await withCheckedThrowingContinuation { continuation in
            continuationsLock.withLock {
                writeContinuations[ref] = continuation
            }

            let dataBytes = Array(data)
            let err = dataBytes.withUnsafeBufferPointer { bufferPtr in
                channel.writeAsync(
                    UnsafeMutableRawPointer(mutating: bufferPtr.baseAddress),
                    length: UInt16(dataBytes.count),
                    refcon: refPointer
                )
            }

            if err != kIOReturnSuccess {
                continuationsLock.withLock {
                    _ = writeContinuations.removeValue(forKey: ref)
                }
                continuation.resume(throwing: RFCOMMError.writeFailed(err))
            }
        }
    }

    // MARK: - Close

    public func close() {
        guard isOpen || channel != nil else { return }
        rfLog("Closing transport")
        isOpen = false
        dataContinuation?.finish()
        dataContinuation = nil

        if let ch = channel {
            ch.close()
            channel = nil
        }
        delegate = nil
        failAllPendingWrites(with: RFCOMMError.channelClosed)
    }

    // MARK: - Private Helpers

    private func handleWriteComplete(ref: UInt, status: IOReturn) {
        let continuation = continuationsLock.withLock {
            writeContinuations.removeValue(forKey: ref)
        }
        if status == kIOReturnSuccess {
            continuation?.resume()
        } else {
            continuation?.resume(throwing: RFCOMMError.writeFailed(status))
        }
    }

    private func failAllPendingWrites(with error: Error) {
        let continuations = continuationsLock.withLock {
            let pending = Array(writeContinuations.values)
            writeContinuations.removeAll()
            return pending
        }
        for cont in continuations {
            cont.resume(throwing: error)
        }
    }
}

// MARK: - Thread-safe Continuation Box

private final class ContinuationBox<T>: @unchecked Sendable {
    private var continuation: CheckedContinuation<T, Error>?
    private let lock = NSLock()

    var isActive: Bool {
        lock.withLock { continuation != nil }
    }

    init(_ continuation: CheckedContinuation<T, Error>) {
        self.continuation = continuation
    }

    func resume(returning value: T) {
        lock.withLock {
            guard let cont = continuation else { return }
            continuation = nil
            cont.resume(returning: value)
        }
    }

    func resume(throwing error: Error) {
        lock.withLock {
            guard let cont = continuation else { return }
            continuation = nil
            cont.resume(throwing: error)
        }
    }
}
