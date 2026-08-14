// Tests/OFBCoreTests/OFBCoreTests.swift

import XCTest
@testable import OFBCore

final class OFBCoreTests: XCTestCase {

    func testCRC16XModem() {
        let input = Data([0x5A, 0x00, 0x03, 0x00, 0x2B, 0x02])
        let crc = CRC16.xmodem(input)
        XCTAssertEqual(crc.count, 2)
    }

    func testHuaweiPacketEncodingDecoding() throws {
        let cmd = Data([0x2B, 0x02])
        let packet = HuaweiPacket(cmd: cmd, parametersList: [(1, Data([0x64]))])
        let encodedData = packet.toData()

        XCTAssertEqual(encodedData[0], 0x5A)
        XCTAssertEqual(encodedData[3], 0x00)

        let decoded = try HuaweiPacket.fromData(encodedData, validateChecksum: true)
        XCTAssertEqual(decoded.commandId, cmd)
        XCTAssertEqual(decoded.findParam(1), Data([0x64]))
    }

    func testDeviceRegistry() {
        XCTAssertTrue(DeviceRegistry.isSupported("HUAWEI FreeBuds Pro 3"))
        XCTAssertTrue(DeviceRegistry.isSupported("HUAWEI FreeBuds Pro 4"))
        XCTAssertTrue(DeviceRegistry.isSupported("HUAWEI FreeBuds 5i"))
        XCTAssertFalse(DeviceRegistry.isSupported("Apple AirPods Pro"))

        let driver = DeviceRegistry.createDriver(name: "HUAWEI FreeBuds Pro 3", address: "11:22:33:44:55:66")
        XCTAssertNotNil(driver)
        XCTAssertEqual(driver?.deviceAddress, "11:22:33:44:55:66")
    }

    func testRPCServerInitialization() async throws {
        let server = RPCServer()
        let manager = await DeviceManager()
        try await server.start(manager: manager, port: 19824)
        await server.stop()
    }
}
