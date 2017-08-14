//
//  MQTTMessage.swift
//  SwiftyFog
//
//  Created by David Giovannini on 5/20/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

class MQTTConnectPacket: MQTTPacket {
    let protocolName: String
    let protocolLevel: UInt8
    let cleanSession: Bool
    let keepAlive: UInt16
    let clientID: String
    
    var username: String? = nil
    var password: String? = nil
    var lastWillMessage: MQTTPubMsg? = nil
    
    init(clientID: String, cleanSession: Bool, keepAlive: UInt16) {
        self.protocolName = "MQTT"
        self.protocolLevel = 0x04
        self.cleanSession = cleanSession
        self.keepAlive = keepAlive
        self.clientID = clientID
        super.init(header: MQTTPacketFixedHeader(packetType: .connect, flags: 0))
    }
    
    private var encodedConnectFlags: UInt8 {
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
    }
	
	override func appendVariableHeader(_ data: inout Data) {
        data.mqttAppend(protocolName)
        data.mqttAppend(protocolLevel)
        data.mqttAppend(encodedConnectFlags)
        data.mqttAppend(keepAlive)
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
