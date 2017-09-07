//
//  MQTTMessage.swift
//  SwiftyFog
//
//  Created by David Giovannini on 5/20/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

public struct MQTTMessage: CustomStringConvertible {
    public let topic: String.UTF8View
    public let payload: Data
    public let retain: Bool
    public let qos: MQTTQoS
	
	init(publishPacket: MQTTPublishPacket) {
		self.topic = publishPacket.message.topic
		self.payload = publishPacket.message.payload
		self.retain = publishPacket.message.retain
		self.qos = publishPacket.message.qos
	}
    
    public init(topic: String, payload: Data = Data(), retain: Bool = false, qos: MQTTQoS = .atMostOnce) {
        self.topic = topic.utf8
        self.payload = payload
        self.retain = retain
        self.qos = qos
    }
	
    public var description: String {
		return "\(topic)\(retain ? "*" : "") - \(qos)\n\t[\(payload.count)] \(payload.fogHexDescription)"
    }
	
    var estimatedPayLoadLength: Int {
		return topic.fogSize + payload.count
    }
}
