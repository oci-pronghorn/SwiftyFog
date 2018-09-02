//
//  MQTTPublishRelPacket.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/13/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation // Data

// Publish release (QoS 2 publish received, part 2)
final class MQTTPublishRelPacket: MQTTPacket, MQTTIdentifiedPacket {
    let messageID: UInt16
	
    init(messageID: UInt16) {
        self.messageID = messageID
        super.init(header: MQTTPacketFixedHeader(packetType: MQTTPacketType.pubRel, flags: 0x02))
    }
	
    init?(header: MQTTPacketFixedHeader, networkData: Data) {
		guard networkData.count >= UInt16.fogSize else { return nil }
		self.messageID = networkData.fogExtract()
        super.init(header: header)
    }
	
    override var expectsAcknowledgement: Bool {
		return true
    }
	
    override var description: String {
		return "\(super.description) id:\(messageID)"
    }
	
    override var estimatedVariableHeaderLength: Int {
		return messageID.fogSize
    }
	
	override func appendVariableHeader(_ data: inout Data) {
		data.mqttAppend(messageID)
    }
}
