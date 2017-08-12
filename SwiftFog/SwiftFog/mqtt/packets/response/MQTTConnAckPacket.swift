//
//  MQTTMessage.swift
//  SwiftFog
//
//  Created by David Giovannini on 5/20/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

class MQTTConnAckPacket: MQTTPacket {
    let sessionPresent: Bool
    let response: MQTTConnAckResponse
    
    init?(header: MQTTPacketFixedHeader, networkData: Data) {
		guard let response = MQTTConnAckResponse(rawValue: networkData[1]) else { return nil }
        self.sessionPresent = (networkData[0] & 0x01) == 0x01
        self.response = response
        super.init(header: header)
    }
}
