//
//  MQTTClient.swift
//  SwiftFog
//
//  Created by David Giovannini on 8/12/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

public struct MQTTClientCredentials {
    // username, password, useSSL, certs, lastWill
}

public struct MQTTClientConnectParams {
    public init(clientID: String) {
        self.clientID = clientID
    }
    public var clientID: String
    public var host: String = "localhost"
    public var port: UInt16 = 1883
    public var cleanSession: Bool = true
    public var keepAlive: UInt16 = 15
    public var useSSL: Bool = false
	
    public var timeout: TimeInterval = 1.0
    public var retryCount: Int = 3
    public var retryTimeInterval: TimeInterval = 1.0
    public var resuscitateTimeInterval: TimeInterval = 5.0
}
