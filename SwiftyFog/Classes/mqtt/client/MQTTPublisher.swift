//
//  MQTTPublisher.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/12/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

protocol MQTTPublisherDelegate: class {
}

final class MQTTPublisher {
	private let durability: MQTTPacketDurability
	private let qos2Mode: Qos2Mode

	private let mutex = ReadWriteMutex()
	private var deferredCompletion = [UInt16 : (Bool)->()]()
	
	weak var delegate: MQTTPublisherDelegate?
	
	init(durability: MQTTPacketDurability, qos2Mode: Qos2Mode) {
		self.durability = durability
		self.qos2Mode = qos2Mode
	}
	
	func connected(cleanSession: Bool, present: Bool, initial: Bool) {
	}
	
	func disconnected(cleanSession: Bool, manual: Bool) {
	}

	func publish(pubMsg: MQTTPubMsg, completion: ((Bool)->())?) {
		let qos = pubMsg.qos
		
		let expecting: MQTTPacketType?
		switch qos {
			case .atMostOnce:
				expecting = nil
				break
			case .atLeastOnce:
				expecting = .pubAck
				break
			case .exactlyOnce:
				expecting = .pubRec
		}
		
		if qos == .atMostOnce {
			let packet = MQTTPublishPacket(messageID: 0, message: pubMsg, isRedelivery: false)
			let success = durability.send(packet: packet)
			completion?(success)
		}
		else {
			let sent: ((MQTTPublishPacket, Bool)->())? = completion == nil ? nil : { [weak self] p, s in
				if (s) { self?.deferredCompletion[p.messageID] = completion }
			}
			durability.send(packet: {MQTTPublishPacket(messageID: $0, message: pubMsg, isRedelivery: false)}, expecting: expecting, sent: sent)
		}
	}
	
	func receive(packet: MQTTPacket) -> Bool {
		switch packet {
			case let ack as MQTTPublishAckPacket: // received for Qos 1
				if let completion = mutex.writing({deferredCompletion.removeValue(forKey:ack.messageID)}) {
					completion(true)
				}
				durability.received(acknolwedgment: ack, releaseId: true)
				return true
			case let rec as MQTTPublishRecPacket: // received for Qos 2 step 1
				if qos2Mode == .lowLatency {
					if let completion = mutex.writing({deferredCompletion.removeValue(forKey:rec.messageID)}) {
						completion(true)
					}
				}
				let rel = MQTTPublishRelPacket(messageID: rec.messageID)
				durability.received(acknolwedgment: rec, releaseId: false)
				durability.send(packet: rel, expecting: .pubComp, sent: nil)
				return true
			case let comp as MQTTPublishCompPacket: // received for Qos 2 step 2
				if qos2Mode == .assured {
					if let completion = mutex.writing({deferredCompletion.removeValue(forKey:comp.messageID)}) {
						completion(true)
					}
				}
				durability.received(acknolwedgment: comp, releaseId: true)
				return true
			default:
				return false
		}
	}
}
