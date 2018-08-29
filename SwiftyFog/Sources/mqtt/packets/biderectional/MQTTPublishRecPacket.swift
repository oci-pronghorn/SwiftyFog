//
//  MQTTPublishRecPacket.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/13/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation // Data

// Publish received (QoS 2 publish received, part 1)
final class MQTTPublishRecPacket: MQTTPacket, MQTTIdentifiedPacket {
    let messageID: UInt16
	
    init(messageID: UInt16) {
        self.messageID = messageID
        super.init(header: MQTTPacketFixedHeader(packetType: MQTTPacketType.pubRec, flags: 0))
    }
	
    override var expectsAcknowledgement: Bool {
		return true
    }
	
    init?(header: MQTTPacketFixedHeader, networkData: Data) {
		guard networkData.count >= UInt16.fogSize else { return nil }
		self.messageID = networkData.fogExtract()
        super.init(header: header)
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
