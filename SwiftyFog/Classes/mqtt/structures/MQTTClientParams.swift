//
//  MQTTClientParams.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/25/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

public struct MQTTClientParams {
    public let clientID: String
    public let cleanSession: Bool
    public let keepAlive: UInt16

    public var lastWill: MQTTMessage? = nil
	
    // Some brokers are not good about treating any packet as a ping
    // Set to false to remove this optimization
    public var treatControlPacketsAsPings = true
    // We can detect server death if we have not received a control packet
    // (including ping ack) in a 1.5 * keepAlive interval
	// TODO: allow stricter time after a ping
    public var detectServerDeath = true
	
	// The spec states that business logic may be invoked on either the 1st or 2nd ack
    public var qos2Mode: Qos2Mode = .lowLatency
    // The spec states that retransmission of disconnected pubs is up to business logic
	// TODO: not implemented yet
	public var queuePubOnDisconnect: MQTTQoS? = nil
	// Spec says we must resend only on reconnect not-clean-session.
	// A non-zero interval will resend while connected
	// TODO: not working yet - has to be > 0.0 and works with queuePubOnDisconnect
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
