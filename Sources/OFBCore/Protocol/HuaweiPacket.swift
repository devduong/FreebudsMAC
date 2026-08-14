// OFBCore/Protocol/HuaweiPacket.swift

import Foundation

public enum HuaweiPacketError: Error, LocalizedError {
    case invalidHeader
    case checksumMismatch
    case packetTooShort

    public var errorDescription: String? {
        switch self {
        case .invalidHeader: return "Invalid Huawei SPP packet header"
        case .checksumMismatch: return "Huawei SPP packet checksum mismatch"
        case .packetTooShort: return "Huawei SPP packet is too short"
        }
    }
}

public struct HuaweiPacket: Sendable, CustomStringConvertible {
    public var commandId: Data   // 2 bytes
    public var responseId: Data  // 2 bytes
    public var parameters: [UInt8: Data]

    // MARK: - Initializers

    public init(commandId: Data, responseId: Data = Data(), parameters: [UInt8: Data] = [:]) {
        precondition(commandId.count == 2, "Command ID must be exactly 2 bytes")
        self.commandId = commandId
        self.responseId = responseId
        self.parameters = parameters
    }

    public init(cmd: Data, parametersList: [(UInt8, Data)]? = nil, resp: Data = Data()) {
        precondition(cmd.count == 2, "Command ID must be 2 bytes")
        self.commandId = cmd
        self.responseId = resp
        self.parameters = [:]

        if let params = parametersList {
            for (pType, pValue) in params {
                self.parameters[pType] = pValue
            }
        }
    }

    // MARK: - Factory Methods

    public static func changeRequest(cmd: Data, parameters: [(UInt8, Data)]) -> HuaweiPacket {
        HuaweiPacket(cmd: cmd, parametersList: parameters, resp: cmd)
    }

    public static func changeRequestNoWait(cmd: Data, parameters: [(UInt8, Data)]) -> HuaweiPacket {
        HuaweiPacket(cmd: cmd, parametersList: parameters)
    }

    public static func readRequest(cmd: Data, parameterTypes: [UInt8]) -> HuaweiPacket {
        let params = parameterTypes.map { ($0, Data()) }
        return HuaweiPacket(cmd: cmd, parametersList: params, resp: cmd)
    }

    // MARK: - Serialization

    /// Convert packet to binary Data ready for wire transmission.
    public func toData() -> Data {
        var body = commandId
        for pType in parameters.keys.sorted() {
            if let pValue = parameters[pType] {
                body.append(pType)
                body.append(UInt8(pValue.count))
                body.append(pValue)
            }
        }

        // Header: 0x5A + (len(body)+1 in 2 bytes big endian) + 0x00 + body
        let length = UInt16(body.count + 1)
        var result = Data()
        result.append(0x5A)
        result.append(UInt8(length >> 8))
        result.append(UInt8(length & 0xFF))
        result.append(0x00)
        result.append(body)

        let crc = CRC16.xmodem(result)
        result.append(crc)
        return result
    }

    // MARK: - Deserialization

    public static func fromData(_ data: Data, validateChecksum: Bool = false) throws -> HuaweiPacket {
        guard data.count >= 6 else {
            throw HuaweiPacketError.packetTooShort
        }
        guard data[0] == 0x5A && data[3] == 0x00 else {
            throw HuaweiPacketError.invalidHeader
        }

        if validateChecksum {
            let crcData = data.dropLast(2)
            let crcValue = data.suffix(2)
            if CRC16.xmodem(crcData) != crcValue {
                throw HuaweiPacketError.checksumMismatch
            }
        }

        let length = Int(data[1]) << 8 | Int(data[2])
        let commandId = data.subdata(in: 4..<6)
        var packet = HuaweiPacket(commandId: commandId)

        var position = 6
        let maxPos = min(length + 3, data.count - 2)

        while position + 2 <= maxPos {
            let pType = data[position]
            let pLength = Int(data[position + 1])
            if position + 2 + pLength > maxPos {
                break
            }
            let pValue = data.subdata(in: (position + 2)..<(position + 2 + pLength))
            packet.parameters[pType] = pValue
            position += 2 + pLength
        }

        return packet
    }

    // MARK: - Parameter Helpers

    public func findParam(_ types: UInt8...) -> Data {
        for t in types {
            if let val = parameters[t] {
                return val
            }
        }
        return Data()
    }

    public var description: String {
        var out = ["command=\(commandId.map { String(format: "%02x", $0) }.joined())"]
        for (t, v) in parameters {
            out.append("param_\(t)=\(v.map { String(format: "%02x", $0) }.joined())")
        }
        return out.joined(separator: ", ")
    }
}
