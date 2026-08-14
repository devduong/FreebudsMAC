// OFBBluetooth/IOBluetoothThread.swift
// Dedicated background thread with NSRunLoop for IOBluetooth operations.
// IOBluetooth delegate callbacks require a thread with an active RunLoop.
// Using main thread causes UI lag; this provides the same RunLoop
// semantics on a dedicated background thread.

@preconcurrency import Foundation

public final class IOBluetoothThread: @unchecked Sendable {
    public static let shared = IOBluetoothThread()

    private var thread: Thread?
    private var runLoop: RunLoop?
    private let readySemaphore = DispatchSemaphore(value: 0)
    private let lock = NSLock()

    private init() {
        let t = Thread { [weak self] in
            self?.threadMain()
        }
        t.name = "com.ofb.iobluetooth"
        t.qualityOfService = .userInitiated
        t.start()
        self.thread = t
        // Wait for RunLoop to be ready
        readySemaphore.wait()
        NSLog("[OFB-BTThread] IOBluetooth background thread started")
    }

    private func threadMain() {
        runLoop = RunLoop.current
        readySemaphore.signal()

        // Keep the RunLoop alive indefinitely by adding a dummy port
        let port = NSMachPort()
        RunLoop.current.add(port, forMode: .default)

        while !Thread.current.isCancelled {
            RunLoop.current.run(mode: .default, before: Date.distantFuture)
        }
    }

    /// Execute a block on the IOBluetooth thread synchronously (blocking caller).
    public func performSync<T>(_ block: @escaping () -> T) -> T {
        guard let rl = runLoop else {
            fatalError("IOBluetoothThread not ready")
        }

        var result: T!
        let sem = DispatchSemaphore(value: 0)

        CFRunLoopPerformBlock(rl.getCFRunLoop(), CFRunLoopMode.defaultMode.rawValue) {
            result = block()
            sem.signal()
        }
        CFRunLoopWakeUp(rl.getCFRunLoop())
        sem.wait()
        return result
    }

    /// Execute a block on the IOBluetooth thread asynchronously.
    public func performAsync(_ block: @escaping @Sendable () -> Void) {
        guard let rl = runLoop else { return }
        CFRunLoopPerformBlock(rl.getCFRunLoop(), CFRunLoopMode.defaultMode.rawValue, block)
        CFRunLoopWakeUp(rl.getCFRunLoop())
    }
}
