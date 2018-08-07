//
//  MQTTMetrics.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/26/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation // Date

public protocol MQTTDebugMetrics {
	func debug(_ out: @autoclosure ()->(String?))
}

protocol MQTTClientMetrics: MQTTDebugMetrics {
	var printSendPackets: Bool { get }
	var printReceivePackets: Bool { get }
	var printUnhandledPackets: Bool { get }
	
	func madeConnection()
	func unhandledPacket()
}

public protocol MQTTWireMetrics: MQTTDebugMetrics {
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

public final class MQTTMetrics: MQTTWireMetrics, MQTTIdMetrics, MQTTClientMetrics, CustomStringConvertible {
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
	
	var printSendPackets: Bool { return printDebug && doPrintSendPackets }
	var printReceivePackets: Bool { return printDebug && doPrintReceivePackets }
	var printUnhandledPackets: Bool { return printDebug && doPrintUnhandledPackets }
	var printIdRetains: Bool { return printDebug && doPrintIdRetains }
	public var printWireData: Bool { return printDebug && doPrintWireData }
	
	public var debugOut: ((String)->())?
	
	public static func verbose() -> MQTTMetrics {
		let metrics = MQTTMetrics()
		metrics.doPrintSendPackets = true
		metrics.doPrintReceivePackets = true
		metrics.debugOut = {
		print("\(Date.nowInSeconds()) MQTT \($0)")}
		
		return metrics
	}
	
	public static func pedantic() -> MQTTMetrics {
		let metrics = MQTTMetrics()
		metrics.doPrintSendPackets = true
		metrics.doPrintReceivePackets = true
		metrics.doPrintWireData = true
		metrics.debugOut = {print("\(Date.nowInSeconds()) MQTT \($0)")}
		return metrics
	}
	
	public init() {
	}
	
	public var description: String {
		return description(indent: "\t")
	}
	
	public func description(indent: String) -> String {
		return """
		\(indent)connectionCount=\(connectionCount)
		\(indent)idsInUse=\(idsInUse)
		\(indent)written=\(written)
		\(indent)writesFailed=\(writesFailed)
		\(indent)received=\(received)
		\(indent)unmarshalFailed=\(unmarshalFailed)
		\(indent)unhandled=\(unhandled)
		"""
	}
	
	var printDebug: Bool { return debugOut != nil }
	
	public func debug(_ out: @autoclosure ()->(String?)) {
		if let debugOut = debugOut {
			if let str = out() {
				debugOut(str)
			}
		}
	}
	
	func madeConnection() {
		connectionCount += 1
	}
	
	func setIdsInUse(idsInUse: Int) {
		self.idsInUse = idsInUse
	}

	public func writingPacket() {
		written += 1
	}
	
	public func failedToWitePcket() {
		writesFailed += 1
	}
	
	public func receivedMessage() {
		received += 1
	}
	
	public func failedToCreatePacket() {
		unmarshalFailed += 1
	}
	
	public func unhandledPacket() {
		unhandled += 1
	}
}
