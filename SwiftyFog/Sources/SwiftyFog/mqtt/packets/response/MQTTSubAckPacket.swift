//
//  MQTTSubAckPacket.swift
//  SwiftyFog
//
//  Created by David Giovannini on 5/20/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation // Data

final class MQTTSubAckPacket: MQTTPacket, MQTTIdentifiedPacket {
    let messageID: UInt16
    let maxQoS: [MQTTQoS?]
    
    init?(header: MQTTPacketFixedHeader, networkData: Data) {
		guard networkData.count >= UInt16.fogSize else { return nil }
		var cursor = 0
        self.messageID = networkData.fogExtract(&cursor)
        let resultCount = networkData.count - cursor
        var maxQoS: [MQTTQoS?] = []
        maxQoS.reserveCapacity(resultCount)
        for _ in 0..<resultCount {
			maxQoS.append(networkData.fogExtract(&cursor))
        }
        self.maxQoS = maxQoS
        super.init(header: header)
    }
	
    override var expectsAcknowledgement: Bool {
		return false
    }
	
    override var description: String {
		return maxQoS.reduce("\(super.description) id:\(messageID)") { (r, e) in
			return r + "\n\t\(e != nil ? String(describing: e!) : "Failed")"
		}
    }
}
