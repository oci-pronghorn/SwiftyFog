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
	public let payload: MQTTPayload
	public let id: UInt16
	public let retain: Bool
	
	internal init(publishPacket: MQTTPublishPacket) {
		self.topic = publishPacket.message.topic
		self.payload = .data(publishPacket.message.payload)
		self.id = publishPacket.messageID
		self.retain = publishPacket.message.retain
	}
    
    public var description: String {
        return "\(id)) \(topic)\(retain ? "*" : "") = \(payload)"
    }
}
