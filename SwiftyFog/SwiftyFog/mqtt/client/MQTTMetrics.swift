//
//  MQTTMetrics.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/26/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

protocol MQTTDebugMetrics {
	func debug(_ out: @autoclosure ()->(String?))
}

protocol MQTTClientMetrics: MQTTDebugMetrics {
	var printSendPackets: Bool { get }
	var printReceivePackets: Bool { get }
	var printUnhandledPackets: Bool { get }
	
	func madeConnection()
	func unhandledPacket()
}

protocol MQTTWireMetrics: MQTTDebugMetrics {
	var printWireData: Bool { get }
	
	func writingPacket()
	func failedToWitePcket()
	func receivedMessage()
	func failedToCreatePacket()
}

protocol MQTTIdMetrics: MQTTDebugMetrics {
	var printIdRetains: Bool { get }
	func setIdsInUse(idsInUse: Int)
}

public final class MQTTMetrics: MQTTWireMetrics, MQTTIdMetrics, MQTTClientMetrics {
	private let prefix: ()->(String)
	
	public private(set) var connectionCount: UInt64 = 0
	
	public private(set) var idsInUse: Int = 0
	public private(set) var written: UInt64 = 0
	public private(set) var writesFailed: UInt64 = 0
	public private(set) var received: UInt64 = 0
	public private(set) var unmarshalFailed: UInt64 = 0
	public private(set) var unhandled: UInt64 = 0
	
	public var doPrintSendPackets: Bool = false
	public var doPrintReceivePackets: Bool = false
	public var doPrintUnhandledPackets: Bool = false
	public var doPrintIdRetains: Bool = false
	public var doPrintWireData: Bool = false
	
	public var printSendPackets: Bool { return printDebug && doPrintSendPackets }
	public var printReceivePackets: Bool { return printDebug && doPrintReceivePackets }
	public var printUnhandledPackets: Bool { return printDebug && doPrintUnhandledPackets }
	public var printIdRetains: Bool { return printDebug && doPrintIdRetains }
	public var printWireData: Bool { return printDebug && doPrintWireData }
	
	public var debugOut: ((String)->())?
	
	public init(prefix: @escaping ()->(String) = {""}) {
		self.prefix = prefix
	}
	
	var printDebug: Bool { return debugOut != nil }
	
	func debug(_ out: @autoclosure ()->(String?)) {
		if let debugOut = debugOut {
			if let str = out() {
				debugOut("\(prefix())\(str)")
			}
		}
	}
	
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
}
