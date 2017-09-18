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
    public var alwaysSendLastWill: Bool = true // If will is set, do not send Dosconnect (cancels last will on server)
	
    // Some brokers are not good about treating any packet as a ping
    // Set to false to remove this optimization
    public var treatControlPacketsAsPings = true
    // We can detect server death if we have not received a control packet
    // after a packet that expects an ack. This defaults to keepAlive * 1.5.
    public var detectServerDeath: UInt16
	
	// The spec states that business logic may be invoked on either the 1st or 2nd ack
    public var qos2Mode: Qos2Mode = .lowLatency
    // The spec states that retransmission of disconnected pubs is up to business logic
	public var queuePubOnDisconnect: MQTTQoS? = nil
	// Spec says we must resend only on reconnect not-clean-session.
	// A non-zero interval will resend while connected
    public var resendPulseInterval: TimeInterval = 5.0
    public var resendLimit: UInt64 = UInt64.max
	
    public init(keepAlive: UInt16) {
		self.clientID = ""
		self.cleanSession = true
		self.keepAlive = keepAlive
		self.detectServerDeath = keepAlive + (keepAlive / 2)
    }
	
    public init(clientID: String, cleanSession: Bool = true, keepAlive: UInt16 = 15) {
		self.clientID = clientID
		self.cleanSession = cleanSession
		self.keepAlive = keepAlive
		self.detectServerDeath = keepAlive + (keepAlive / 2)
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
		self.detectServerDeath = keepAlive + (keepAlive / 2)
	}
}
