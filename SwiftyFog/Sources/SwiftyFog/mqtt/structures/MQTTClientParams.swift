//
//  MQTTClientParams.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/25/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

#if os(iOS)
import UIKit
#else
import Foundation // Bundle
#endif

public struct MQTTClientParams {
    public let clientID: String
    public let cleanSession: Bool
    public let keepAlive: UInt16
    public var lastWill: MQTTMessage? = nil
	
    // Some brokers are not good about treating any packet as a ping
    // Set to false to remove this optimization
    public var treatControlPacketsAsPings = true
    // We can detect server death if we have not received an ack packet
    // after a packet that expects one. This defaults to keepAlive * 1.5.
    public var detectServerDeath: UInt16
    // If will is set, do not send DisconnectPacket. DisconnectPacket will cancel last will on server.
    public var alwaysSendLastWill: Bool = true
	
    public init(keepAlive: UInt16) {
		self.clientID = ""
		self.cleanSession = true // must be true for empty clientID
		self.keepAlive = keepAlive
		self.detectServerDeath = keepAlive + (keepAlive / 2)
    }
	
    public init(clientID: String, cleanSession: Bool = true, keepAlive: UInt16 = 15) {
		self.clientID = clientID
		self.cleanSession = cleanSession || !clientID.isEmpty // must be true for empty clientID
		self.keepAlive = keepAlive
		self.detectServerDeath = keepAlive + (keepAlive / 2)
    }
	
	public init(cleanSession: Bool = true, keepAlive: UInt16 = 15) {
		self.clientID = MQTTClientParams.hardwareClientId()
		self.cleanSession = cleanSession
		self.keepAlive = keepAlive
		self.detectServerDeath = keepAlive + (keepAlive / 2)
	}
	
	public static func hardwareClientId() -> String {
      // 1 and 23 UTF-8 encoded bytes
      // Only "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    #if os(iOS)
      	let deviceID = UIDevice.current.identifierForVendor!.uuidString
		let platform = "iOS"
    #elseif os(OSX)
      	let deviceID = String.macUUID
		let platform = "OSX"
	#elseif os(watchOS)
      	let deviceID = UUID().uuidString
		let platform = "wOS"
	#elseif os(Linux)
      	let deviceID = UUID().uuidString
		let platform = "Lnx"
    #endif
		let appId = Bundle.main.bundleIdentifier!
		let fullId = appId + "-" + deviceID
		let hash = Int64(fullId.hash)
		let uhash = UInt64(bitPattern: hash)
		let asciied = platform + String(format: "%20lu", uhash)
		return asciied
	}
}

#if os(OSX)
private extension String {
	static var macUUID : String {
		get
		{
			var hwUUIDBytes: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
			var ts = timespec(tv_sec: 0,tv_nsec: 0)
			gethostuuid(&hwUUIDBytes, &ts)
			return NSUUID(uuidBytes: hwUUIDBytes).uuidString
		}
	}
}
#endif
