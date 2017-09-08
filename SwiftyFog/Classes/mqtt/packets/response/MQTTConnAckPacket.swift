//
//  MQTTConnAckPacket.swift
//  SwiftyFog
//
//  Created by David Giovannini on 5/20/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

class MQTTConnAckPacket: MQTTPacket {
    let sessionPresent: Bool
    let response: MQTTConnAckResponse
    
    init?(header: MQTTPacketFixedHeader, networkData: Data) {
		guard networkData.count >= (MQTTConnAckResponse.fogSize + Bool.fogSize) else { return nil }
        self.sessionPresent = (networkData[0] & 0x01) == 0x01
        self.response = MQTTConnAckResponse(specValue: networkData[1])
        super.init(header: header)
    }
	
    override var description: String {
		return "\(super.description): \(response) present=\(sessionPresent)"
    }
}
