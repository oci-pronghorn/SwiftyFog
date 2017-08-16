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
    
    init(header: MQTTPacketFixedHeader) {
        self.header = header
    }
	
    var fixedHeaderLength: Int {
		return 1
    }
	
    var estimatedVariableHeaderLength: Int {
		return 0
    }
	
    var estimatedPayLoadLength: Int {
		return 0
    }
	
	func appendVariableHeader(_ data: inout Data) {
	}
	
	func appendPayload(_ data: inout Data) {
	}
}
