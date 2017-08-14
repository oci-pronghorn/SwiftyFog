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
    
    init?(networkByte: UInt8) {
		guard let packetType = MQTTPacketType(rawValue: networkByte >> 4) else { return nil }
        self.packetType = packetType
        self.flags = networkByte & 0x0F
    }
    
    var networkByte : UInt8 {
        return (0x0F & flags) | (packetType.rawValue << 4)
    }
}
