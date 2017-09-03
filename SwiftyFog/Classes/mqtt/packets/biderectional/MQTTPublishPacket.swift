//
//  MQTTPublishPacket.swift
//  SwiftyFog
//
//  Created by David Giovannini on 5/20/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

// Publish payload (QoS 0 final)
class MQTTPublishPacket: MQTTPacket, MQTTIdentifiedPacket {
    let messageID: UInt16
    let message: MQTTMessage
    
    init(messageID: UInt16, message: MQTTMessage, isRedelivery: Bool = false) {
        self.messageID = messageID
        self.message = message
        super.init(header: MQTTPacketFixedHeader(packetType: .publish, flags: MQTTPublishPacket.fixedHeaderFlags(for: message, isRedelivery: isRedelivery)))
    }
	
    override var description: String {
		return "\(super.description) id:\(messageID) \(message)"
    }
    
    func dupForResend() -> MQTTPacket {
		return MQTTPublishPacket(messageID: messageID, message: message, isRedelivery: true)
    }
	
    init?(header: MQTTPacketFixedHeader, networkData: Data) {
		guard networkData.count >= UInt16.fogSize else { return nil }
        let topicLength = 256 * Int(networkData[0]) + Int(networkData[1])
		guard networkData.count >= UInt16.fogSize + topicLength else { return nil }
        let topicData = networkData.subdata(in: 2..<topicLength+2)
		
		guard let qos = MQTTQoS(rawValue: (header.flags & 0x06) >> 1) else { return nil }
		guard let topic = String(data: topicData, encoding: .utf8) else { return nil }
		
        var payload = networkData.subdata(in: 2+topicLength..<networkData.endIndex)
		
        if qos != .atMostOnce {
            self.messageID = payload.fogExtract()
            payload = payload.subdata(in: 2..<payload.endIndex)
        } else {
            self.messageID = 0
        }
		
        let retain = (header.flags & 0x01) == 0x01
		self.message = MQTTMessage(topic: topic, payload: payload, retain: retain, qos: qos)
		
        super.init(header: header)
    }
    
    private static func fixedHeaderFlags(for message: MQTTMessage, isRedelivery: Bool) -> UInt8 {
        var flags = UInt8(0)
        if message.retain {
            flags |= 0x01
        }
        flags |= message.qos.rawValue << 1
        if isRedelivery && message.qos != .atMostOnce {
			flags |= 0x08
        }
        return flags
    }
	
    override var estimatedVariableHeaderLength: Int {
		var s = message.topic.fogSize
        if message.qos != .atMostOnce {
            s += messageID.fogSize
        }
		return s
    }
	
	override func appendVariableHeader(_ data: inout Data) {
        data.mqttAppend(message.topic)
        if message.qos != .atMostOnce {
            data.mqttAppend(messageID)
        }
	}
	
    override var estimatedPayLoadLength: Int {
		return message.payload.count
    }
	
    override func appendPayload(_ data: inout Data) {
		data.append(message.payload)
    }
}
