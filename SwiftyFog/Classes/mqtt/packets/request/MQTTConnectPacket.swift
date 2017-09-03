//
//  MQTTConnectPacket.swift
//  SwiftyFog
//
//  Created by David Giovannini on 5/20/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

class MQTTConnectPacket: MQTTPacket {
    let protocolName: String.UTF8View
    let protocolLevel: UInt8
    let cleanSession: Bool
    let keepAlive: UInt16
    let clientID: String.UTF8View
    
    var username: String.UTF8View? = nil
    var password: String.UTF8View? = nil
    var lastWillMessage: MQTTMessage? = nil
    
    init(clientID: String, cleanSession: Bool, keepAlive: UInt16) {
        self.protocolName = "MQTT".utf8
        self.protocolLevel = 0x04
        self.cleanSession = cleanSession
        self.keepAlive = keepAlive
        self.clientID = clientID.utf8
        super.init(header: MQTTPacketFixedHeader(packetType: .connect, flags: 0))
    }
	
    override var description: String {
		var desc = "\(super.description): \(protocolName).\(protocolLevel) '\(clientID)'\(cleanSession ? "" : "*") \(keepAlive)secs"
		if username != nil || password != nil {
			desc += " w/auth"
		}
		if let lastWillMessage = lastWillMessage {
			desc += "\n\tWill: \(lastWillMessage)"
		}
		return desc
    }
    
    private lazy var encodedConnectFlags: UInt8 = {
        var flags = UInt8(0)
        if cleanSession {
            flags |= 0x02
        }
        if let message = lastWillMessage {
            flags |= 0x04
            if message.retain {
                flags |= 0x20
            }
            let qos = message.qos.rawValue
            flags |= qos << 3
        }
        if username != nil {
            flags |= 0x80
        }
        if password != nil {
            flags |= 0x40
        }
        return flags
    }()
	
    override var estimatedVariableHeaderLength: Int {
		return
			protocolName.fogSize +
			protocolLevel.fogSize +
			encodedConnectFlags.fogSize +
			keepAlive.fogSize
    }
	
	override func appendVariableHeader(_ data: inout Data) {
        data.mqttAppend(protocolName)
        data.mqttAppend(protocolLevel)
        data.mqttAppend(encodedConnectFlags)
        data.mqttAppend(keepAlive)
	}
	
    override var estimatedPayLoadLength: Int {
		let a = clientID.fogSize
		let b = lastWillMessage?.estimatedPayLoadLength ?? 0
		let c = username?.fogSize ?? 0
		let d = password?.fogSize ?? 0
		return a + b + c + d
    }
	
    override func appendPayload(_ data: inout Data) {
        data.mqttAppend(clientID)
        if let message = lastWillMessage {
            data.mqttAppend(message.topic)
            data.mqttAppend(message.payload)
        }
        if let username = username {
            data.mqttAppend(username)
        }
        if let password = password {
            data.mqttAppend(password)
        }
	}
}
