//
//  MQTTPacketFixedHeader.swift
//  SwiftyFog
//
//  Created by David Giovannini on 5/20/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

struct MQTTPacketFixedHeader {
    let packetType: MQTTPacketType
    let flags: UInt8
    
    init(packetType: MQTTPacketType, flags: UInt8) {
        self.packetType = packetType
        self.flags = flags
    }
    
    init?(memento: UInt8) {
		guard let packetType = MQTTPacketType(rawValue: memento >> 4) else { return nil }
        self.packetType = packetType
        self.flags = memento & 0x0F
    }
    
    var memento : UInt8 {
        return (0x0F & flags) | (packetType.rawValue << 4)
    }
}
