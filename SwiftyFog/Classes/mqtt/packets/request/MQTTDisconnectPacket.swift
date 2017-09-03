//
//  MQTTDisconnectPacket.swift
//  SwiftyFog
//
//  Created by David Giovannini on 5/20/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

class MQTTDisconnectPacket: MQTTPacket {
    init() {
        super.init(header: MQTTPacketFixedHeader(packetType: .disconnect, flags: 0))
    }
}
