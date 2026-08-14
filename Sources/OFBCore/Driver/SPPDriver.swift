// OFBCore/Driver/SPPDriver.swift

import Foundation
import OFBBluetooth

open class SPPDriver: BaseDriver, @unchecked Sendable {
    public var sppServicePort: Int = 16
    public var sppConnectDelay: TimeInterval = 0

    private var transport: RFCOMMTransport?
    private var recvTask: Task<Void, Never>?

    public override init(address: String) {
        super.init(address: address)
    }

    open override func start() async throws {
        let transport = RFCOMMTransport()
        let stream = try await transport.open(
            address: deviceAddress,
            channel: sppServicePort,
            connectDelay: sppConnectDelay
        )
        self.transport = transport

        recvTask = Task { [weak self] in
            await self?.loopRecv(stream: stream)
        }

        try await super.start()
    }

    open override func stop() async {
        await super.stop()
        recvTask?.cancel()
        recvTask = nil
        transport?.close()
        transport = nil
    }

    open override func healthy() -> Bool {
        return super.healthy() && (transport?.isOpen ?? false) && !(recvTask?.isCancelled ?? true)
    }

    open func writeData(_ data: Data) async throws {
        guard let transport = transport, transport.isOpen else {
            throw NSError(domain: "OFBCore", code: 500, userInfo: [NSLocalizedDescriptionKey: "SPP transport is not connected"])
        }
        try await transport.write(data)
    }

    open func loopRecv(stream: AsyncStream<Data>) async {
        for await _ in stream {
            if Task.isCancelled { break }
        }
    }
}
