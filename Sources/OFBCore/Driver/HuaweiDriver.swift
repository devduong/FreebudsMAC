// OFBCore/Driver/HuaweiDriver.swift

import Foundation

// MARK: - Huawei Handler Protocol

public protocol HuaweiHandler: DriverHandler {
    var handlerId: String { get }
    var commands: [Data] { get }
    var ignoreCommands: [Data] { get }

    var driver: HuaweiDriver? { get set }

    func initHandler() async
    func onInit() async throws
    func onPackage(_ package: HuaweiPacket) async
}

extension HuaweiHandler {
    public func initHandler() async {
        var attempt = 0
        let maxAttempt = 2
        let timeoutSeconds: UInt64 = 5

        while attempt < maxAttempt {
            do {
                try await withTimeout(seconds: timeoutSeconds) {
                    try await self.onInit()
                }
                NSLog("[OFB-Huawei] Handler '%@' initialized successfully", handlerId)
                return
            } catch {
                attempt += 1
                NSLog("[OFB-Huawei] Handler '%@' init attempt %d failed: %@", handlerId, attempt, error.localizedDescription)
            }
        }

        NSLog("[OFB-Huawei] Can't initialize handler '%@'. Skipping.", handlerId)
    }
}

// MARK: - Timeout Helper

private func withTimeout<T: Sendable>(seconds: UInt64, operation: @escaping @Sendable () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }

        group.addTask {
            try await Task.sleep(nanoseconds: seconds * 1_000_000_000)
            throw TimeoutError()
        }

        guard let result = try await group.next() else {
            throw TimeoutError()
        }
        group.cancelAll()
        return result
    }
}

public struct TimeoutError: Error, LocalizedError {
    public var errorDescription: String? { "Operation timed out" }
}

// MARK: - Huawei Driver

open class HuaweiDriver: SPPDriver, @unchecked Sendable {
    public var handlers: [HuaweiHandler] = []

    private var pendingResponses: [Data: CheckedContinuation<HuaweiPacket?, Error>] = [:]
    private var pendingResponsePackages: [Data: HuaweiPacket] = [:]
    private var onPackageHandlers: [Data: HuaweiHandler] = [:]
    private let huaweiLock = NSLock()

    private var rxBuffer = Data()

    public override init(address: String) {
        super.init(address: address)
    }

    open override func start() async throws {
        try await super.start()
        await startAllHandlers()
    }

    open override func stop() async {
        await super.stop()
        huaweiLock.withLock {
            onPackageHandlers.removeAll()
            pendingResponses.removeAll()
            pendingResponsePackages.removeAll()
        }
        rxBuffer.removeAll()
    }

    private func startAllHandlers() async {
        for handler in handlers {
            handler.driver = self
            addSetPropertyHandler(handler)
            for cmd in handler.commands {
                huaweiLock.withLock {
                    onPackageHandlers[cmd] = handler
                }
            }
        }

        for handler in handlers {
            await handler.initHandler()
        }
    }

    // MARK: - Send Package

    public func sendPackage(_ pkg: HuaweiPacket, timeout: TimeInterval = 3) async throws -> HuaweiPacket? {
        if pkg.responseId.isEmpty {
            try await sendNoWait(pkg)
            return nil
        }

        let responseId = pkg.responseId

        return try await withCheckedThrowingContinuation { continuation in
            huaweiLock.withLock {
                pendingResponses[responseId] = continuation
            }

            Task {
                do {
                    try await self.sendNoWait(pkg)
                } catch {
                    self.huaweiLock.withLock {
                        if let cont = self.pendingResponses.removeValue(forKey: responseId) {
                            cont.resume(throwing: error)
                        }
                    }
                }
            }

            // Timeout handle
            Task {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                self.huaweiLock.withLock {
                    if let cont = self.pendingResponses.removeValue(forKey: responseId) {
                        cont.resume(returning: nil)
                    }
                }
            }
        }
    }

    public func sendNoWait(_ pkg: HuaweiPacket) async throws {
        let data = pkg.toData()
        try await writeData(data)
    }

    // MARK: - Receive Loop & Framing

    open override func loopRecv(stream: AsyncStream<Data>) async {
        for await chunk in stream {
            if Task.isCancelled { break }
            rxBuffer.append(chunk)

            while rxBuffer.count >= 4 {
                let start = rxBuffer.startIndex
                guard rxBuffer[start] == 0x5A else {
                    // Resync by dropping first byte
                    rxBuffer.removeFirst()
                    continue
                }

                let length = Int(rxBuffer[start + 1]) << 8 | Int(rxBuffer[start + 2])
                let totalPkgLen = length + 5 // 0x5A + 2 len + 0x00 + length bytes

                if totalPkgLen < 6 || totalPkgLen > 4096 {
                    // Invalid length, resync
                    rxBuffer.removeFirst()
                    continue
                }

                if rxBuffer.count >= totalPkgLen {
                    let rawPkg = Data(rxBuffer[start..<(start + totalPkgLen)])
                    rxBuffer.removeFirst(totalPkgLen)
                    await handleRawPkg(rawPkg)
                } else {
                    break
                }
            }
        }
    }

    private func handleRawPkg(_ rawData: Data) async {
        guard let pkg = try? HuaweiPacket.fromData(rawData) else {
            NSLog("[OFB-Huawei] Failed to parse HuaweiPacket from %d bytes rawData", rawData.count)
            return
        }

        let cmdId = pkg.commandId
        let hexCmd = cmdId.map { String(format: "%02X", $0) }.joined()

        let pendingCont = huaweiLock.withLock { () -> CheckedContinuation<HuaweiPacket?, Error>? in
            if let cont = pendingResponses.removeValue(forKey: cmdId) {
                return cont
            }
            if cmdId == Data([0x01, 0x27]), let cont = pendingResponses.removeValue(forKey: Data([0x01, 0x08])) {
                return cont
            }
            return nil
        }

        if let cont = pendingCont {
            NSLog("[OFB-Huawei] handleRawPkg cmdId %@ matched pendingResponse", hexCmd)
            cont.resume(returning: pkg)
            return
        }

        let handler = huaweiLock.withLock {
            onPackageHandlers[cmdId]
        }

        NSLog("[OFB-Huawei] handleRawPkg cmdId %@ handler: %@", hexCmd, handler?.handlerId ?? "none")

        if let h = handler {
            await h.onPackage(pkg)
        }
    }
}
