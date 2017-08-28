//
//  MQTTMetrics.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/26/17.
//

import Foundation

public final class MQTTMetrics {
	private let prefix: ()->(String)
	
	public private(set) var connectionCount: UInt64 = 0
	
	public private(set) var idsInUse: Int = 0
	public private(set) var written: UInt64 = 0
	public private(set) var writesFailed: UInt64 = 0
	public private(set) var received: UInt64 = 0
	public private(set) var unmarshalFailed: UInt64 = 0
	public private(set) var unhandled: UInt64 = 0
	
	func madeConnection() {
		connectionCount += 1
	}
	
	func setIdsInUse(idsInUse: Int) {
		self.idsInUse = idsInUse
	}

	func writingPacket() {
		written += 1
	}
	
	func failedToWitePcket() {
		writesFailed += 1
	}
	
	func receivedMessage() {
		received += 1
	}
	
	func failedToCreatePacket() {
		unmarshalFailed += 1
	}
	
	func unhandledPacket() {
		unhandled += 1
	}
	
	public var consoleOut: ((String)->())?
	public var debugOut: ((String)->())?
	
	public init(prefix: @escaping ()->(String) = {""}) {
		self.prefix = prefix
	}
	
	public func print(_ out: @autoclosure ()->(String?)) {
		if let consoleOut = consoleOut {
			if let str = out() {
				consoleOut("\(prefix())\(str)")
			}
		}
	}
	
	public func debug(_ out: @autoclosure ()->(String?)) {
		if let debugOut = debugOut {
			if let str = out() {
				debugOut("\(prefix())\(str)")
			}
		}
	}
}
