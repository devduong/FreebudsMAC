// OFBCore/Protocol/CRC16.swift

import Foundation

public enum CRC16 {
    /// Calculate CRC16-XMODEM checksum for input data.
    /// Returns 2 bytes in big-endian byte order.
    public static func xmodem(_ data: Data) -> Data {
        var crc: UInt16 = 0x0000
        for byte in data {
            crc ^= (UInt16(byte) << 8)
            for _ in 0..<8 {
                if (crc & 0x8000) != 0 {
                    crc = (crc << 1) ^ 0x1021
                } else {
                    crc <<= 1
                }
            }
        }
        var bigEndian = crc.bigEndian
        return Data(bytes: &bigEndian, count: 2)
    }

    /// Calculate CRC16-XMODEM as UInt16.
    public static func xmodemUInt16(_ data: Data) -> UInt16 {
        var crc: UInt16 = 0x0000
        for byte in data {
            crc ^= (UInt16(byte) << 8)
            for _ in 0..<8 {
                if (crc & 0x8000) != 0 {
                    crc = (crc << 1) ^ 0x1021
                } else {
                    crc <<= 1
                }
            }
        }
        return crc
    }
}
