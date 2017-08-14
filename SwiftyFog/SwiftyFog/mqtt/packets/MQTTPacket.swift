//
//  MQTTMessage.swift
//  SwiftyFog
//
//  Created by David Giovannini on 5/20/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

public class MQTTPacket {
    let header: MQTTPacketFixedHeader
    
    init(header: MQTTPacketFixedHeader) {
        self.header = header
    }
	
	func appendVariableHeader(_ data: inout Data) {
	}
	
	func appendPayload(_ data: inout Data) {
	}
	
	func writeTo(data: inout Data) {
		// TODO: memory manage this payload data for recycling
		var payload = Data(capacity: 1024)
		self.appendVariableHeader(&payload)
		self.appendPayload(&payload)
		
		data.fogAppend(header.networkByte)
		data.mqttAppendRemaining(length: payload.count)
		data.append(payload)
	}
}
