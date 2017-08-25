//
//  MQTTClientParams.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/25/17.
//

import Foundation

public struct MQTTClientParams {
    public var clientID: String
    public var cleanSession: Bool
    public var keepAlive: UInt16
    public var lastWill: MQTTPubMsg? = nil
    
    public var detectServerDeath = false
	
    public var qos2Mode: Qos2Mode = .lowLatency
	public var queuePubOnDisconnect: MQTTQoS? = nil
    public var resendPulseInterval: TimeInterval = 5.0
	
    public init(clientID: String, cleanSession: Bool = true, keepAlive: UInt16 = 60) {
		self.clientID = clientID
		self.cleanSession = cleanSession
		self.keepAlive = keepAlive
    }
	
	public init(cleanSession: Bool = true, keepAlive: UInt16 = 60) {
		// 1 and 23 UTF-8 encoded bytes
		// Only "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
		let deviceID = UIDevice.current.identifierForVendor!.uuidString
		let appId = Bundle.main.bundleIdentifier!
		let fullId = appId + "-" + deviceID
		let hash = Int64(fullId.hash)
		let uhash = UInt64(bitPattern: hash)
		let asciied = String(format: "ios%20lu", uhash)
		self.clientID = asciied
		self.cleanSession = cleanSession
		self.keepAlive = keepAlive
	}
}
