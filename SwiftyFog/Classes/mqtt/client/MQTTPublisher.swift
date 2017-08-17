//
//  MQTTPublisher.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/12/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

protocol MQTTPublisherDelegate: class {
	func send(packet: MQTTPacket) -> Bool
}

private struct PublishAttempt {
	var packet: MQTTPublishPacket
	var completion: ((Bool)->())?
}

public enum Qos2Mode {
	case lowLatency
	case assured
}

final class MQTTPublisher {
	private let idSource: MQTTMessageIdSource
	private let qos2Mode: Qos2Mode

	private let mutex = ReadWriteMutex()
	private typealias PendingPublish = [UInt16:PublishAttempt]
	private var unacknowledgedQos1Ack = PendingPublish()
	private var unacknowledgedQos2Rec = PendingPublish()
	private var unacknowledgedQos2Comp = PendingPublish()
	
	weak var delegate: MQTTPublisherDelegate?
	
	init(idSource: MQTTMessageIdSource, qos2Mode: Qos2Mode) {
		self.idSource = idSource
		self.qos2Mode = qos2Mode
	}
	
	func connected(cleanSession: Bool, present: Bool) {
		if cleanSession == false {
			for messageId in unacknowledgedQos1Ack.keys.sorted() {
				if let element = unacknowledgedQos1Ack[messageId] {
					let packet = MQTTPublishPacket(messageID: element.packet.messageID, message: element.packet.message, isRedelivery: true)
					let _ = delegate?.send(packet: packet)
				}
			}
			for messageId in unacknowledgedQos2Rec.keys.sorted() {
				if let element = unacknowledgedQos2Rec[messageId] {
					let packet = MQTTPublishPacket(messageID: element.packet.messageID, message: element.packet.message, isRedelivery: true)
					let _ = delegate?.send(packet: packet)
				}
			}
			for messageId in unacknowledgedQos2Comp.keys.sorted() {
				let packet = MQTTPublishRecPacket(messageID: messageId)
				let _ = delegate?.send(packet: packet)
			}
		}
	}
	
	func resendPulse() {
		mutex.writing {
			// TODO
		}
	}
	
	func disconnected(cleanSession: Bool, manual: Bool) {
		var unacknowledgedQos1Ack = PendingPublish()
		var unacknowledgedQos2Rec = PendingPublish()
		var unacknowledgedQos2Comp = PendingPublish()
		mutex.writing {
			unacknowledgedQos1Ack = self.unacknowledgedQos1Ack
			unacknowledgedQos2Rec = self.unacknowledgedQos2Rec
			unacknowledgedQos2Comp = self.unacknowledgedQos2Comp
			if cleanSession {
				self.unacknowledgedQos1Ack.keys.forEach(idSource.free)
				self.unacknowledgedQos1Ack.removeAll()
				self.unacknowledgedQos2Rec.keys.forEach(idSource.free)
				self.unacknowledgedQos2Rec.removeAll()
				self.unacknowledgedQos2Comp.keys.forEach(idSource.free)
				self.unacknowledgedQos2Comp.removeAll()
			}
		}
		if cleanSession || manual {
			for element in unacknowledgedQos1Ack {
				idSource.free(id: element.0)
				element.1.completion?(false)
			}
			for element in unacknowledgedQos2Rec {
				idSource.free(id: element.0)
				element.1.completion?(false)
			}
			for element in unacknowledgedQos2Comp {
				idSource.free(id: element.0)
				element.1.completion?(false)
			}
		}
	}

	func publish(pubMsg: MQTTPubMsg, completion: ((Bool)->())?) {
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
				unacknowledgedQos1Ack[messageId] = PublishAttempt(packet: packet, completion: completion)
			}
			else if qos == .exactlyOnce {
				unacknowledgedQos2Rec[messageId] = PublishAttempt(packet: packet, completion: completion)
			}
		}
		if delegate?.send(packet: packet) ?? false == false {
			if messageId != 0 {
				idSource.free(id: messageId)
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
	
	func receive(packet: MQTTPacket) -> Bool {
		switch packet {
			case let packet as MQTTPublishAckPacket: // received for Qos 1
				idSource.free(id: packet.messageID)
				if let element = mutex.writing({unacknowledgedQos1Ack.removeValue(forKey:packet.messageID)}) {
					element.completion?(true)
				}
				return true
			case let packet as MQTTPublishRecPacket: // received for Qos 2 step 1
				let rel = MQTTPublishRelPacket(messageID: packet.messageID)
				let element = mutex.writing({unacknowledgedQos2Rec.removeValue(forKey:packet.messageID)})
				if qos2Mode == .lowLatency {
					if let element = mutex.writing({unacknowledgedQos2Comp.removeValue(forKey:packet.messageID)}) {
						element.completion?(true)
					}
				}
				let success = delegate?.send(packet: rel) ?? false
				if qos2Mode == .assured {
					if let element = element, success == true {
						mutex.writing { unacknowledgedQos2Comp[packet.messageID] = element }
					}
				}
				return true
			case let packet as MQTTPublishCompPacket: // received for Qos 2 step 2
				idSource.free(id: packet.messageID)
				if qos2Mode == .assured {
					if let element = mutex.writing({unacknowledgedQos2Comp.removeValue(forKey:packet.messageID)}) {
						element.completion?(true)
					}
				}
				return true
			default:
				return false
		}
	}
}
