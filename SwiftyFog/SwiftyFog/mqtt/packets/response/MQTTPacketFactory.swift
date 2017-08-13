//
//  MQTTMessage.swift
//  SwiftyFog
//
//  Created by David Giovannini on 5/20/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

struct MQTTPacketFactory {
    let constructors: [MQTTPacketType : (MQTTPacketFixedHeader, Data)->MQTTPacket?] = [
        .connAck : MQTTConnAckPacket.init,
        .pingAck : { h, _ in MQTTPingAckPacket.init(header: h) },
        .publish : MQTTPublishPacket.init,
        .pubAck : MQTTPublishAckPacket.init,
        .pubRec : MQTTPublishRecPacket.init,
        .pubComp : MQTTPublishCompPacket.init,
        .subAck : MQTTSubAckPacket.init,
        .unSubAck : MQTTUnSubAckPacket.init,
    ]
	
    func send(_ packet: MQTTPacket, _ writer: StreamWriter) -> Bool {
		var data = Data(capacity: 1024)
		packet.writeTo(data: &data)
		print("Sent Bytes: \(type(of:packet)) \(data.count) \(data.hexDescription)")
		return data.write(to: writer)
    }

    func parse(_ read: StreamReader) -> (Bool, MQTTPacket?) {
        var headerByte: UInt8 = 0
        let headerReadLen = read(&headerByte, 1)
		guard headerReadLen > 0 else { return (true, nil) }
        if let header = MQTTPacketFixedHeader(networkByte: headerByte) {
			if let len = MQTTPacketFactory.readMqttPackedLength(from: read) {
				if let data = Data(len: len, from: read) {
					print("Received Bytes: \(header.packetType) \(data.count) \(data.hexDescription)")
					return (false, constructors[header.packetType]?(header, data))
				}
			}
		}
        return (false, nil)
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
