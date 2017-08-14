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
		guard networkData.count >= 2 else { return nil }
		self.messageID = networkData.fogExtract()
        super.init(header: header)
    }
}