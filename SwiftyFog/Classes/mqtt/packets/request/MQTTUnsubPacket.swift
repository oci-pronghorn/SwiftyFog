//
//  MQTTMessage.swift
//  SwiftyFog
//
//  Created by David Giovannini on 5/20/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

class MQTTUnsubPacket: MQTTPacket, MQTTIdentifiedPacket {
    let topics: [String.UTF8View]
    let messageID: UInt16
    
    init(topics: [String], messageID: UInt16) {
        self.topics = topics.map { $0.utf8 }
        self.messageID = messageID
        super.init(header: MQTTPacketFixedHeader(packetType: .unSubscribe, flags: 0x02))
    }
	
    override var estimatedVariableHeaderLength: Int {
		return messageID.fogSize
    }
	
	override func appendVariableHeader(_ data: inout Data) {
		data.mqttAppend(messageID)
    }
	
    override var estimatedPayLoadLength: Int {
		return topics.reduce(0) { (last, element) in
			return last + element.fogSize
		}
    }
	
    override func appendPayload(_ data: inout Data) {
        for topic in topics {
            data.mqttAppend(topic)
        }
	}
}
