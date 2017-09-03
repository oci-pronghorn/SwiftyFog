//
//  MQTTPublishAckPacket.swift
//  SwiftyFog
//
//  Created by David Giovannini on 5/20/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

// Publish acknowledged (QoS 1 publish received, final)
class MQTTPublishAckPacket: MQTTPacket, MQTTIdentifiedPacket {
    let messageID: UInt16
    
    init(messageID: UInt16) {
        self.messageID = messageID
        super.init(header: MQTTPacketFixedHeader(packetType: MQTTPacketType.pubAck, flags: 0))
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
