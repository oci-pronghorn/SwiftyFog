//
//  MQTTMessage.swift
//  SwiftFog
//
//  Created by David Giovannini on 5/20/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

struct MQTTPacketFactory {
    let constructors: [MQTTPacketType : (MQTTPacketFixedHeader, Data)->MQTTPacket?] = [
        .connAck : MQTTConnAckPacket.init,
        .subAck : MQTTSubAckPacket.init,
        .unSubAck : MQTTUnSubAckPacket.init,
        .pubAck : MQTTPubAck.init,
        .publish : MQTTPublishPacket.init,
        .pingResp : { h, _ in MQTTPingResp.init(header: h) }
    ]

    func parse(_ read: StreamReader) -> MQTTPacket? {
        var headerByte: UInt8 = 0
        let headerReadLen = read(&headerByte, 1)
		guard headerReadLen > 0 else { return nil }
        if let header = MQTTPacketFixedHeader(networkByte: headerByte) {
			if let len = MQTTPacketFactory.readMqttPackedLength(from: read) {
				if let data = Data(len: len, from: read) {
					return constructors[header.packetType]?(header, data)
				}
			}
		}
        return nil
	}

	private static func readMqttPackedLength(from read: StreamReader) -> Int? {
		var multiplier = 1
		var value = 0
		var encodedByte: UInt8 = 0
		repeat {
			let bytesRead = read(&encodedByte, 1)
			if bytesRead < 0 {
				return nil
			}
			value += (Int(encodedByte) & 127) * multiplier
			multiplier *= 128
		} while ((Int(encodedByte) & 128) != 0)
		return value <= 128*128*128 ? value : nil
	}
}
