//
//  MQTTMessage.swift
//  SwiftyFog
//
//  Created by David Giovannini on 5/20/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

public struct MQTTMessage: CustomStringConvertible {
	public let topic: String
	public let payload: Data //MQTTPayload
	public let id: UInt16
	public let retain: Bool
	public let qos: MQTTQoS
	
	init(publishPacket: MQTTPublishPacket) {
		self.topic = String(publishPacket.message.topic)
		self.payload = publishPacket.message.payload
		self.id = publishPacket.messageID
		self.retain = publishPacket.message.retain
		self.qos = publishPacket.message.qos
	}
    
    public var description: String {
        return "\(id)) \(topic) \(qos)\(retain ? "*" : "") = \(payload)"
    }
}
