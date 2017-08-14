//
//  MQTTMessage.swift
//  SwiftyFog
//
//  Created by David Giovannini on 5/20/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

class MQTTUnsubPacket: MQTTPacket {
    let topics: [String]
    let messageID: UInt16
    
    init(topics: [String], messageID: UInt16) {
        self.topics = topics
        self.messageID = messageID
        super.init(header: MQTTPacketFixedHeader(packetType: .unSubscribe, flags: 0x02))
    }
	
	override func appendVariableHeader(_ data: inout Data) {
		data.mqttAppend(messageID)
    }
	
    override func appendPayload(_ data: inout Data) {
        for topic in topics {
            data.mqttAppend(topic)
        }
	}
}
