//
//  MQTTMessage.swift
//  SwiftyFog
//
//  Created by David Giovannini on 5/20/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

// Publish received (QoS 0 final)
class MQTTPublishPacket: MQTTPacket {
    let messageID: UInt16
    let message: MQTTPubMsg
    
    init(messageID: UInt16, message: MQTTPubMsg, isRedelivery: Bool = false) {
        self.messageID = messageID
        self.message = message
        super.init(header: MQTTPacketFixedHeader(packetType: .publish, flags: MQTTPublishPacket.fixedHeaderFlags(for: message, isRedelivery: isRedelivery)))
    }
	
    init?(header: MQTTPacketFixedHeader, networkData: Data) {
		guard networkData.count >= 2 else { return nil }
        let topicLength = 256 * Int(networkData[0]) + Int(networkData[1])
		guard networkData.count >= 2 + topicLength else { return nil }
        let topicData = networkData.subdata(in: 2..<topicLength+2)
		
		guard let qos = MQTTQoS(rawValue: header.flags & 0x06) else { return nil }
		guard let topic = String(data: topicData, encoding: .utf8) else { return nil }
		
        var payload = networkData.subdata(in: 2+topicLength..<networkData.endIndex)
		
        if qos != .atMostOnce {
            self.messageID = payload.fogExtract()
            payload = payload.subdata(in: 2..<payload.endIndex)
        } else {
            self.messageID = 0
        }
		
        let retain = (header.flags & 0x01) == 0x01
        self.message = MQTTPubMsg(topic: topic, payload: payload, retain: retain, QoS: qos)
		
        super.init(header: header)
    }
    
    private static func fixedHeaderFlags(for message: MQTTPubMsg, isRedelivery: Bool) -> UInt8 {
        var flags = UInt8(0)
        if message.retain {
            flags |= 0x01
        }
        flags |= message.QoS.rawValue << 1
        if isRedelivery && message.QoS != .atMostOnce {
			flags |= 0x08
        }
        return flags
    }
	
	override func appendVariableHeader(_ data: inout Data) {
        data.mqttAppend(message.topic)
        if message.QoS != .atMostOnce {
            data.mqttAppend(messageID)
        }
	}
	
    override func appendPayload(_ data: inout Data) {
		data.append(message.payload)
    }
}
