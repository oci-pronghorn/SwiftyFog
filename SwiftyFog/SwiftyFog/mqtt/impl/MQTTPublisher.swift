//
//  MQTTPublisher.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/12/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

final class MQTTPublisher {
	private let issuer: MQTTPacketIssuer
	private let queuePubOnDisconnect: MQTTQoS?
	private let qos2Mode: Qos2Mode

	private let mutex = ReadWriteMutex()
	private var deferredCompletion = [UInt16 : (Bool)->()]()
		
	init(issuer: MQTTPacketIssuer, queuePubOnDisconnect: MQTTQoS?, qos2Mode: Qos2Mode) {
		self.issuer = issuer
		self.queuePubOnDisconnect = queuePubOnDisconnect
		self.qos2Mode = qos2Mode
	}
	
	func connected(cleanSession: Bool, present: Bool, initial: Bool) {
	}
	
	func disconnected(cleanSession: Bool, stopped: Bool) {
	}

	func publish(pubMsg: MQTTMessage, completion: ((Bool)->())?) {
		let qos = pubMsg.qos
		
		if qos == .atMostOnce {
			let packet = MQTTPublishPacket(messageID: 0, message: pubMsg, isRedelivery: false)
			issuer.send(packet: packet) { packet, success in
				completion?(success)
			}
		}
		else {
			let sent: ((MQTTPublishPacket, Bool)->())? = completion == nil ? nil : { [weak self] p, s in
				if (s) { self?.deferredCompletion[p.messageID] = completion }
			}
			issuer.send(packet: {MQTTPublishPacket(messageID: $0, message: pubMsg, isRedelivery: false)}, sent: sent)
		}
	}
	
	func receive(packet: MQTTPacket) -> Bool {
		switch packet {
			case let ack as MQTTPublishAckPacket: // received for Qos 1
				if let completion = mutex.writing({deferredCompletion.removeValue(forKey:ack.messageID)}) {
					completion(true)
				}
				issuer.received(acknolwedgment: ack, releaseId: true)
				return true
			case let rec as MQTTPublishRecPacket: // received for Qos 2 step 1
				if qos2Mode == .lowLatency {
					if let completion = mutex.writing({deferredCompletion.removeValue(forKey:rec.messageID)}) {
						completion(true)
					}
				}
				let rel = MQTTPublishRelPacket(messageID: rec.messageID)
				issuer.received(acknolwedgment: rec, releaseId: false)
				issuer.send(packet: rel, sent: nil)
				return true
			case let comp as MQTTPublishCompPacket: // received for Qos 2 step 2
				if qos2Mode == .assured {
					if let completion = mutex.writing({deferredCompletion.removeValue(forKey:comp.messageID)}) {
						completion(true)
					}
				}
				issuer.received(acknolwedgment: comp, releaseId: true)
				return true
			default:
				return false
		}
	}
}
