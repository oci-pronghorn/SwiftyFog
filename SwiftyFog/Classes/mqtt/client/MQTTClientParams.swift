//
//  MQTTClientParams.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/25/17.
//

import Foundation

public struct MQTTClientParams {
    public let clientID: String
    public let cleanSession: Bool
    public let keepAlive: UInt16
	
    public var lastWill: MQTTPubMsg? = nil
	
    // Some brokers are good about acks and can be treated as server is alive
    public var detectServerDeath = false
    // Some brokers are good about treating any packet as a ping
    public var treatControlPacketsAsPings = false
	
	// The spec states that business logic may be invoked on either the 1st or 2nd ack
    public var qos2Mode: Qos2Mode = .lowLatency
    // The spec states that retransmission of disconnected pubs is up to business logic
	public var queuePubOnDisconnect: MQTTQoS? = nil
	// There is no spec on the rate of unacknowledged pubs
    public var resendPulseInterval: TimeInterval = 5.0
	
    public init(clientID: String, cleanSession: Bool = true, keepAlive: UInt16 = 15) {
		self.clientID = clientID
		self.cleanSession = cleanSession
		self.keepAlive = keepAlive
    }
	
	public init(cleanSession: Bool = true, keepAlive: UInt16 = 15) {
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
