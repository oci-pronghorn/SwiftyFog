//
//  MQTTMessage.swift
//  SwiftFog
//
//  Created by David Giovannini on 5/20/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

public struct MQTTPubMsg {
    public let topic: String
    public let payload: Data
    public let retain: Bool
    public let QoS: MQTTQoS
    
    public init(topic: String, payload: Data, retain: Bool, QoS: MQTTQoS) {
        self.topic = topic
        self.payload = payload
        self.retain = retain
        self.QoS = QoS
    }
}
