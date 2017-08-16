//
//  MQTTMessage.swift
//  SwiftyFog
//
//  Created by David Giovannini on 5/20/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

struct MQTTPacketFactory {
    private let constructors: [MQTTPacketType : (MQTTPacketFixedHeader, Data)->MQTTPacket?] = [
        .connAck : MQTTConnAckPacket.init,
        .pingAck : { h, _ in MQTTPingAckPacket.init(header: h) },
        .publish : MQTTPublishPacket.init,
        .pubAck : MQTTPublishAckPacket.init,
        .pubRec : MQTTPublishRecPacket.init,
        .pubRel : MQTTPublishRelPacket.init,
        .pubComp : MQTTPublishCompPacket.init,
        .subAck : MQTTSubAckPacket.init,
        .unSubAck : MQTTUnsubAckPacket.init,
    ]
	
	var debugOut: ((String)->())?
	
	func send(_ packet: MQTTPacket, _ writer: StreamWriter) -> Bool {
		let data = write(packet)
		if let debugOut = debugOut {
			debugOut("Sent Bytes: \(type(of:packet)) \(data.count) \(data.hexDescription)")
		}
		return data.write(to: writer)
    }
	
    private func write(_ packet: MQTTPacket) -> Data {
		let fhl = packet.fixedHeaderLength
		let fsl = 4
		let capacity: Int = fhl + fsl + packet.estimatedVariableHeaderLength + packet.estimatedPayLoadLength
		var data = Data(capacity: capacity)
		data.fogAppend(packet.header.networkByte)
		data.fogAppend(UInt32(0)) // placeholder
		packet.appendVariableHeader(&data)
		packet.appendPayload(&data)
		let payloadLize = data.count - (fhl + fsl)
		let sizeInBytes = data.mqttInsertRemaining(at: fhl, length: payloadLize)
		let offset = 4 - sizeInBytes
		if offset > 0 {
			if payloadLize > 0 {
				data.replaceSubrange(
					(fhl+sizeInBytes)..<(data.count-offset),
					with: data.subdata(in: (fhl+fsl)..<data.count))
			}
			data = data.subdata(in: 0..<(data.count-offset))
		}
		return data
	}

    func parse(_ read: StreamReader) -> (Bool, MQTTPacket?) {
        var headerByte: UInt8 = 0
        let headerReadLen = read(&headerByte, 1)
		guard headerReadLen > 0 else { return (true, nil) }
        if let header = MQTTPacketFixedHeader(networkByte: headerByte) {
			if let len = Data.readMqttPackedLength(from: read) {
				if let data = Data(len: len, from: read) {
					if let debugOut = debugOut {
						debugOut("Received Bytes: \(header.packetType) \(data.count) \(data.hexDescription)")
					}
					return (false, constructors[header.packetType]?(header, data))
				}
			}
		}
        return (false, nil)
	}
}
