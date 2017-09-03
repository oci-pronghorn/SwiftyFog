//
//  MQTTPacketFactory.swift
//  SwiftyFog
//
//  Created by David Giovannini on 5/20/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

struct MQTTPacketFactory {
    private let constructors: [MQTTPacketType : (MQTTPacketFixedHeader, Data)->MQTTPacket?] = [
        .connAck : MQTTConnAckPacket.init,
        .pingAck : MQTTPingAckPacket.init,
        .publish : MQTTPublishPacket.init,
        .pubAck : MQTTPublishAckPacket.init,
        .pubRec : MQTTPublishRecPacket.init,
        .pubRel : MQTTPublishRelPacket.init,
        .pubComp : MQTTPublishCompPacket.init,
        .subAck : MQTTSubAckPacket.init,
        .unSubAck : MQTTUnsubAckPacket.init,
    ]
	
	private let metrics: MQTTMetrics?
	
	init( metrics: MQTTMetrics?) {
		self.metrics = metrics
	}
	
	func send(_ packet: MQTTPacket, _ writer: FogSocketStreamWrite) -> Bool {
		let data = marshal(packet)
		var success = false
		metrics?.writingPacket()
		writer({ w in
			success = data.write(to: w)
			if success == false {
				metrics?.failedToWitePcket()
			}
		})
		return success
    }
	
    func receive(_ read: StreamReader) -> (Bool, MQTTPacket?) {
		metrics?.receivedMessage()
		let result = unmarshal(read)
		if result.1 == nil && result.0 == true {
			metrics?.failedToCreatePacket()
		}
		return result
    }
	
    private static let filler = [UInt8](repeating: 0, count: MQTTPacket.fixedHeaderLength + MQTTPackedLength.maxLen)
	
    private func marshal(_ packet: MQTTPacket) -> Data {
		let fcl = MQTTPacketFactory.filler.count
		let fhl = MQTTPacket.fixedHeaderLength
		let fsl = fcl - fhl
		let fbl = fhl + fsl
		let capacity = fbl + packet.estimatedVariableHeaderLength + packet.estimatedPayLoadLength
		var data = Data(capacity: capacity)
		data.append(contentsOf: MQTTPacketFactory.filler)
		packet.appendVariableHeader(&data)
		packet.appendPayload(&data)
		let variableSize = data.count - fbl
		let lengthSize = MQTTPackedLength.bytesRquired(for: variableSize)
		MQTTPackedLength.replace(in: &data, at: fcl - lengthSize, length: variableSize)
		let remainder = fsl - lengthSize
		data[remainder] = packet.header.memento
		data = data.subdata(in: remainder..<data.count)
		if let metrics = metrics, metrics.debugOut != nil, metrics.printWireData {
			let realCapacity = capacity - remainder
			if realCapacity < data.count {
				metrics.debug("Underallocated: \(type(of:packet)) \(data.count) > \(realCapacity)")
			}
			else if realCapacity > data.count {
				metrics.debug("Overallocated: \(type(of:packet)) \(data.count) < \(realCapacity)")
			}
			metrics.debug("Wire->: \(type(of:packet)) [\(data.count)] \(data.fogHexDescription)")
		}
		return data
    }

    private func unmarshal(_ read: StreamReader) -> (Bool, MQTTPacket?) {
        var headerByte: UInt8 = 0
        let headerReadLen = read(&headerByte, MQTTPacket.fixedHeaderLength)
		guard headerReadLen > 0 else { return (true, nil) }
		if let len = MQTTPackedLength.read(from: read) {
			if let data = Data(len: len, from: read) {
				if let header = MQTTPacketFixedHeader(memento: headerByte) {
					if let metrics = metrics, metrics.debugOut != nil, metrics.printWireData {
						let lenSize = MQTTPackedLength.bytesRquired(for: len)
						let len = data.count + MQTTPacket.fixedHeaderLength + lenSize
						let headerStr = String(format: "%02x.", headerByte)
						let lenStr = (0..<lenSize).reduce("", { r, _ in return r + "##." })
						metrics.debug("Wire<-: \(header.packetType) [\(len)] \(headerStr)\(lenStr)\(data.fogHexDescription)")
					}
					return (false, constructors[header.packetType]?(header, data))
				}
			}
		}
        return (false, nil)
	}
}
