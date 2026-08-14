// OFBCore/EventBus.swift

import Foundation

public struct OfbEvent: @unchecked Sendable {
    public let kind: String
    public let group: String?
    public let prop: String?
    public let value: Any?

    public init(kind: String, group: String? = nil, prop: String? = nil, value: Any? = nil) {
        self.kind = kind
        self.group = group
        self.prop = prop
        self.value = value
    }
}

public actor EventBus {
    private var subscribers: [UUID: (filters: [String]?, continuation: AsyncStream<OfbEvent>.Continuation)] = [:]

    public init() {}

    public func subscribe(filters: [String]? = nil) -> (id: UUID, stream: AsyncStream<OfbEvent>) {
        let id = UUID()
        let (stream, continuation) = AsyncStream<OfbEvent>.makeStream()
        subscribers[id] = (filters, continuation)
        return (id, stream)
    }

    public func unsubscribe(id: UUID) {
        if let sub = subscribers.removeValue(forKey: id) {
            sub.continuation.finish()
        }
    }

    public func send(_ event: OfbEvent) {
        for (_, sub) in subscribers {
            if let filters = sub.filters, !filters.contains(event.kind) {
                continue
            }
            sub.continuation.yield(event)
        }
    }
}
