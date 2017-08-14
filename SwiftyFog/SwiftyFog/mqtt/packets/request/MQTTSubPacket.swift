//
//  MQTTMessage.swift
//  SwiftyFog
//
//  Created by David Giovannini on 5/20/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

class MQTTSubPacket: MQTTPacket {
    let topics: [String: MQTTQoS]
    let messageID: UInt16
    
    init(topics: [String: MQTTQoS], messageID: UInt16) {
        self.topics = topics
        self.messageID = messageID
        super.init(header: MQTTPacketFixedHeader(packetType: .subscribe, flags: 0x02))
    }
	
	override func appendVariableHeader(_ data: inout Data) {
		data.mqttAppend(messageID)
    }
	
    override func appendPayload(_ data: inout Data) {
        for (key, value) in topics {
			data.mqttAppend(key)
            let qos: UInt8 = value.rawValue & 0x03
			data.mqttAppend(qos)
		}
    }
}
