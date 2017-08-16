//
//  MQTTMessage.swift
//  SwiftyFog
//
//  Created by David Giovannini on 5/20/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

class MQTTSubAckPacket: MQTTPacket {
    let messageID: UInt16
    
    init?(header: MQTTPacketFixedHeader, networkData: Data) {
		guard networkData.count >= UInt16.mqttLength else { return nil }
        self.messageID = networkData.fogExtract()
        super.init(header: header)
    }
}
