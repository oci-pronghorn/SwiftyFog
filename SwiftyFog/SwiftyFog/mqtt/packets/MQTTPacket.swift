//
//  MQTTMessage.swift
//  SwiftyFog
//
//  Created by David Giovannini on 5/20/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

class MQTTPacket {
    let header: MQTTPacketFixedHeader
    
    init?(header: MQTTPacketFixedHeader) {
        self.header = header
    }
	
	func appendVariableHeader(_ data: inout Data) {
	}
	
	func appendPayload(_ data: inout Data) {
	}
	
	func writeTo(data: inout Data) {
		self.appendVariableHeader(&data)
		data.fogAppend(header.networkByte)
		var payload = Data(capacity: 1024)
		self.appendPayload(&payload)
		data.mqttAppendRemaining(length: payload.count)
		data.append(payload)
	}
}
