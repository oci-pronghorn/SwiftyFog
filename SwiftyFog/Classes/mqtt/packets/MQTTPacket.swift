//
//  MQTTPacket.swift
//  SwiftyFog
//
//  Created by David Giovannini on 5/20/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

class MQTTPacket: CustomStringConvertible {
    let header: MQTTPacketFixedHeader
    
    init(header: MQTTPacketFixedHeader) {
        self.header = header
    }
	
    var expectsAcknowledgement: Bool {
		return false
    }
	
    static let fixedHeaderLength: Int = 1
	
    var description: String {
		return "\(header.packetType)"
    }
	
    var estimatedPayLoadLength: Int {
		return 0
    }
	
	func appendVariableHeader(_ data: inout Data) {
	}
	
    var estimatedVariableHeaderLength: Int {
		return 0
    }
	
	func appendPayload(_ data: inout Data) {
	}
}

protocol MQTTIdentifiedPacket {
    var messageID: UInt16 { get }
    func dupForResend() -> MQTTPacket
}

extension MQTTIdentifiedPacket where Self: MQTTPacket {
    func dupForResend() -> MQTTPacket {
		return self
    }
}
