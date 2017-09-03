//
//  MQTTSubPacket.swift
//  SwiftyFog
//
//  Created by David Giovannini on 5/20/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

class MQTTSubPacket: MQTTPacket, MQTTIdentifiedPacket {
    let topics: [(String.UTF8View, MQTTQoS)]
    let messageID: UInt16
    
    init(topics: [(String, MQTTQoS)], messageID: UInt16) {
        self.topics = topics.map { ($0.0.utf8, $0.1) }
        self.messageID = messageID
        super.init(header: MQTTPacketFixedHeader(packetType: .subscribe, flags: 0x02))
    }
	
    override var description: String {
		return topics.reduce("\(super.description) id:\(messageID) ") { (r, e) in
			return r + "\n\t\(e.0) - \(e.1)"
		}
    }
	
    override var estimatedVariableHeaderLength: Int {
		return messageID.fogSize
    }
	
	override func appendVariableHeader(_ data: inout Data) {
		data.mqttAppend(messageID)
    }
	
    override var estimatedPayLoadLength: Int {
		return topics.reduce(0) { (last, element) in
			return last + element.0.fogSize + element.1.fogSize
		}
    }
	
    override func appendPayload(_ data: inout Data) {
        for (topic, qos) in topics {
			data.mqttAppend(topic)
			data.mqttAppend(qos.rawValue)
		}
    }
}
