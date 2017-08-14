//
//  MQTTPublisher.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/12/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

public struct MQTTPublishRetry {
	public var retryCount: UInt = 0
	public var retryIntervalSecs: UInt = 0

	public init() {
	}
}

public protocol MQTTPublisherDelegate: class {
	func send(packet: MQTTPacket) -> Bool
}

public class MQTTPublisher {
	private let idSource: MQTTMessageIdSource
	
	// TODO: publish retries -
		// we are *permitted* to resend with new message ids until full handshake is done (not Qos0)
		// completion timeouts

	private let mutex = ReadWriteMutex()
	private typealias PendingPublish = [UInt16:(MQTTPublishPacket,((Bool)->())?)]
	private var unacknowledgedQos1Ack = PendingPublish()
	private var unacknowledgedQos2Rec = PendingPublish()
	private var unacknowledgedQos2Comp = PendingPublish()
	
	public weak var delegate: MQTTPublisherDelegate?
	
	public init(idSource: MQTTMessageIdSource) {
		self.idSource = idSource
	}
	
	public func connected(cleanSession: Bool) {
		if cleanSession == false {
			for messageId in unacknowledgedQos1Ack.keys.sorted() {
				if let element = unacknowledgedQos1Ack[messageId] {
					let _ = delegate?.send(packet: element.0)
				}
			}
			for messageId in unacknowledgedQos2Rec.keys.sorted() {
				if let element = unacknowledgedQos2Rec[messageId] {
					let _ = delegate?.send(packet: element.0)
				}
			}
			for messageId in unacknowledgedQos2Comp.keys.sorted() {
				let packet = MQTTPublishRecPacket(messageID: messageId)
				let _ = delegate?.send(packet: packet)
			}
		}
	}
	
	public func disconnected(cleanSession: Bool, final: Bool) {
		var unacknowledgedQos1Ack = PendingPublish()
		var unacknowledgedQos2Rec = PendingPublish()
		var unacknowledgedQos2Comp = PendingPublish()
		mutex.writing {
			unacknowledgedQos1Ack = self.unacknowledgedQos1Ack
			unacknowledgedQos2Rec = self.unacknowledgedQos2Rec
			unacknowledgedQos2Comp = self.unacknowledgedQos2Comp
			if cleanSession {
				self.unacknowledgedQos1Ack.keys.forEach(idSource.release)
				self.unacknowledgedQos1Ack.removeAll()
				self.unacknowledgedQos2Rec.keys.forEach(idSource.release)
				self.unacknowledgedQos2Rec.removeAll()
				self.unacknowledgedQos2Comp.keys.forEach(idSource.release)
				self.unacknowledgedQos2Comp.removeAll()
			}
		}
		if cleanSession || final {
			for element in unacknowledgedQos1Ack {
				idSource.release(id: element.0)
				element.1.1?(false)
			}
			for element in unacknowledgedQos2Rec {
				idSource.release(id: element.0)
				element.1.1?(false)
			}
			for element in unacknowledgedQos2Comp {
				idSource.release(id: element.0)
				element.1.1?(false)
			}
		}
	}

	public func publish(
			pubMsg: MQTTPubMsg,
			retry: MQTTPublishRetry = MQTTPublishRetry(),
			completion: ((Bool)->())?) {
		var messageId = UInt16(0)
		if pubMsg.qos != .atMostOnce {
			messageId = idSource.fetch()
		}
		let packet = MQTTPublishPacket(messageID: messageId, message: pubMsg, isRedelivery: false)
		performPublish(packet: packet, completion: completion)
	}
	
	private func performPublish(packet: MQTTPublishPacket, completion: ((Bool)->())?) {
		let qos = packet.message.qos
		let messageId = packet.messageID
		mutex.writing {
			if qos == .atLeastOnce {
				unacknowledgedQos1Ack[messageId] = (packet, completion)
			}
			else if qos == .exactlyOnce {
				unacknowledgedQos2Rec[messageId] = (packet, completion)
			}
		}
		if delegate?.send(packet: packet) ?? false == false {
			if messageId != 0 {
				idSource.release(id: messageId)
			}
			mutex.writing {
				if qos == .atLeastOnce {
					unacknowledgedQos1Ack.removeValue(forKey: messageId)
				}
				else if qos == .exactlyOnce {
					unacknowledgedQos2Rec.removeValue(forKey: messageId)
				}
			}
			completion?(false)
			return
		}
		if qos == .atMostOnce {
			completion?(true)
		}
	}
	
	public func receive(packet: MQTTPacket) -> Bool {
		switch packet {
			case let packet as MQTTPublishAckPacket: // received for Qos 1
				if let element = mutex.writing({unacknowledgedQos1Ack.removeValue(forKey:packet.messageID)}) {
					idSource.release(id: element.0.messageID)
					element.1?(true)
				}
				return true
			case let packet as MQTTPublishRecPacket: // received for Qos 2.a
				if let element = mutex.writing({unacknowledgedQos2Rec.removeValue(forKey:packet.messageID)}) {
					// TODO: the broker kills connection when receiving this poison pill!
					let rel = MQTTPublishRelPacket(messageID: packet.messageID)
					if let success = delegate?.send(packet: rel), success == true {
						mutex.writing { unacknowledgedQos2Comp[packet.messageID] = element }
					}
				}
				return true
			case let packet as MQTTPublishCompPacket: // received for Qos 2.b
				if let element = mutex.writing({unacknowledgedQos2Comp.removeValue(forKey:packet.messageID)}) {
					idSource.release(id: element.0.messageID)
					element.1?(true)
				}
				return true
			default:
				return false
		}
	}
}
