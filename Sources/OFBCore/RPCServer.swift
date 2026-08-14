// OFBCore/RPCServer.swift
// Using native macOS Network framework (NWListener)

import Foundation
import Network

public actor RPCServer {
    public static let defaultPort: UInt16 = 19823

    private var listener: NWListener?
    private weak var manager: DeviceManager?
    private var isRunning: Bool = false

    public init() {}

    public func start(manager: DeviceManager, port: UInt16 = defaultPort) throws {
        guard !isRunning else { return }
        self.manager = manager

        let nwPort = NWEndpoint.Port(rawValue: port)!
        let params = NWParameters.tcp
        let listener = try NWListener(using: params, on: nwPort)

        listener.newConnectionHandler = { [weak self] connection in
            Task {
                await self?.handleConnection(connection)
            }
        }

        listener.start(queue: .global(qos: .userInitiated))
        self.listener = listener
        self.isRunning = true
    }

    public func stop() {
        listener?.cancel()
        listener = nil
        isRunning = false
    }

    // MARK: - Connection Handler

    private func handleConnection(_ connection: NWConnection) async {
        connection.start(queue: .global(qos: .userInitiated))

        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let data = data, !data.isEmpty, let self = self else {
                connection.cancel()
                return
            }

            Task {
                let response = await self.processHttpRequest(data)
                connection.send(content: response, completion: .contentProcessed({ _ in
                    connection.cancel()
                }))
            }
        }
    }

    // MARK: - HTTP Request Processing

    private func processHttpRequest(_ requestData: Data) async -> Data {
        guard let requestString = String(data: requestData, encoding: .utf8) else {
            return makeHttpResponse(status: 400, body: "{\"error\":\"Bad Request\"}")
        }

        let lines = requestString.components(separatedBy: "\r\n")
        guard let firstLine = lines.first else {
            return makeHttpResponse(status: 400, body: "{\"error\":\"Bad Request\"}")
        }

        let parts = firstLine.components(separatedBy: " ")
        guard parts.count >= 2 else {
            return makeHttpResponse(status: 400, body: "{\"error\":\"Bad Request\"}")
        }

        let method = parts[0]
        let path = parts[1]

        // Route matching
        if path == "/__rpc__/ping" || path == "/ping" {
            return makeHttpResponse(status: 200, body: "pong", contentType: "text/plain")
        }

        if path == "/list_shortcuts" {
            let shortcuts = ShortcutAction.allCases.map { $0.rawValue }
            if let json = try? JSONSerialization.data(withJSONObject: shortcuts),
               let jsonStr = String(data: json, encoding: .utf8) {
                return makeHttpResponse(status: 200, body: jsonStr)
            }
        }

        if path.hasPrefix("/__rpc__/") {
            let action = String(path.dropFirst("/__rpc__/".count))
            return await handleRpcAction(action, method: method, requestString: requestString)
        }

        // Shortcut endpoint: /{shortcut}
        let shortcutName = String(path.dropFirst())
        if let shortcut = ShortcutAction(rawValue: shortcutName), let mgr = manager {
            do {
                try await mgr.shortcuts.execute(shortcut)
                return makeHttpResponse(status: 200, body: "{\"result\":true}")
            } catch {
                return makeHttpResponse(status: 500, body: "{\"error\":\"\(error.localizedDescription)\"}")
            }
        }

        return makeHttpResponse(status: 404, body: "{\"error\":\"Not Found\"}")
    }

    private func handleRpcAction(_ action: String, method: String, requestString: String) async -> Data {
        guard let mgr = manager else {
            return makeHttpResponse(status: 503, body: "{\"error\":\"Manager unavailable\"}")
        }

        switch action {
        case "get_state":
            let state = await mgr.state.rawValue
            return makeHttpResponse(status: 200, body: "{\"state\":\(state)}")
        case "get_health_report":
            let report: [String: Any] = [
                "device_name": await mgr.deviceName,
                "device_address": await mgr.deviceAddress,
                "state": await mgr.state.rawValue
            ]
            if let json = try? JSONSerialization.data(withJSONObject: report),
               let jsonStr = String(data: json, encoding: .utf8) {
                return makeHttpResponse(status: 200, body: jsonStr)
            }
            return makeHttpResponse(status: 200, body: "{}")
        case "stop":
            await mgr.stop()
            return makeHttpResponse(status: 200, body: "{\"result\":true}")
        default:
            return makeHttpResponse(status: 404, body: "{\"error\":\"Unknown RPC action\"}")
        }
    }

    private func makeHttpResponse(status: Int, body: String, contentType: String = "application/json") -> Data {
        let statusText = (status == 200) ? "OK" : (status == 404 ? "Not Found" : "Error")
        let response = """
        HTTP/1.1 \(status) \(statusText)\r
        Content-Type: \(contentType)\r
        Content-Length: \(body.utf8.count)\r
        Access-Control-Allow-Origin: *\r
        Connection: close\r
        \r
        \(body)
        """
        return Data(response.utf8)
    }
}
