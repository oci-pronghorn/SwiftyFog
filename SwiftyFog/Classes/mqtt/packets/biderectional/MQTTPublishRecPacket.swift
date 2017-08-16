//
//  MQTTPublishRecPacket.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/13/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

// Publish received (QoS 2 publish received, part 1)
class MQTTPublishRecPacket: MQTTPacket {
    let messageID: UInt16
	
    init(messageID: UInt16) {
        self.messageID = messageID
        super.init(header: MQTTPacketFixedHeader(packetType: MQTTPacketType.pubRec, flags: 0))
    }
	
    init?(header: MQTTPacketFixedHeader, networkData: Data) {
		guard networkData.count >= UInt16.mqttLength else { return nil }
		self.messageID = networkData.fogExtract()
        super.init(header: header)
    }
	
    override var estimatedVariableHeaderLength: Int {
		return messageID.mqttLength
    }
	
	override func appendVariableHeader(_ data: inout Data) {
		data.mqttAppend(messageID)
    }
}
