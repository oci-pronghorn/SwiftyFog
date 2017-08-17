//
//  MQTTDistributer.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/13/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

public final class MQTTRegistration {
	fileprivate weak var distributor: MQTTDistributor? = nil
	fileprivate let token: UInt64
	public let path: String
	
	fileprivate init(token: UInt64, path: String) {
		self.token = token
		self.path = path
	}
	
	deinit {
		distributor?.unregisterTopic(token: token, path: path)
	}
}

protocol MQTTDistributorDelegate: class {
	func send(packet: MQTTPacket) -> Bool
	func unhandledMessage(message: MQTTMessage)
}

final class MQTTDistributor {
	private let idSource: MQTTMessageIdSource
	private let qos2Mode: Qos2Mode
	
	weak var delegate: MQTTDistributorDelegate?
	
	private let mutex = ReadWriteMutex()
	private var token: UInt64 = 0
	private var registeredPaths = [String: [(UInt64,(MQTTMessage)->())]]()
	private var unacknowledgedQos2Rel = [UInt16:MQTTPublishPacket]()
	private var unsentAcks = [UInt16:MQTTPacket]()
	
	init(idSource: MQTTMessageIdSource, qos2Mode: Qos2Mode) {
		self.idSource = idSource
		self.qos2Mode = qos2Mode
	}
	
	func connected(cleanSession: Bool, present: Bool) {
	}
	
	func resendPulse() {
		mutex.writing {
			// Resend acks that failed to send
			for messageId in unsentAcks.keys.sorted() {
				let packet = unsentAcks[messageId]!
				if delegate?.send(packet: packet) ?? false == true {
					unsentAcks.removeValue(forKey: messageId)
				}
			}
			// Resend packets that have failed to get an 
			for messageId in unacknowledgedQos2Rel.keys.sorted() {
				let packet = MQTTPublishRecPacket(messageID: messageId)
				let _ = delegate?.send(packet: packet) // ignore failure will resnd on next timer
			}
		}
	}
	
	func disconnected(cleanSession: Bool, manual: Bool) {
		if cleanSession == true {
			mutex.writing {
				unacknowledgedQos2Rel.removeAll()
				unsentAcks.removeAll()
			}
		}
	}
	
	func registerTopic(path: String, action: @escaping (MQTTMessage)->()) -> MQTTRegistration {
		return mutex.writing {
			token += 1
			let entity = (token, action)
			registeredPaths.computeIfAbsent(path, {_ in [entity]}, { $1.append(entity) })
			return MQTTRegistration(token: token, path: path)
		}
	}
	
	fileprivate func unregisterTopic(token: UInt64, path: String) {
		return mutex.writing {
			if let tokens = registeredPaths[path] {
				for i in 0..<tokens.count {
					if tokens[i].0 == token {
						registeredPaths[path]!.remove(at: i)
					}
				}
			}
		}
	}
	
	private func issue(packet: MQTTPublishPacket) {
		var actions = [(MQTTMessage)->()]()
		mutex.reading {
			if let distribute = registeredPaths[String(packet.message.topic)] {
				for action in distribute {
					actions.append(action.1)
				}
			}
		}
		let msg = MQTTMessage(publishPacket: packet)
		actions.forEach { $0(msg) }
		if actions.count == 0 {
			delegate?.unhandledMessage(message: msg)
		}
	}

	func receive(packet: MQTTPacket) -> Bool {
		switch packet {
			case let packet as MQTTPublishPacket:
				switch packet.message.qos {
					case .atMostOnce:
						issue(packet: packet)
						break
					case .atLeastOnce:
						issue(packet: packet)
						let ack = MQTTPublishAckPacket(messageID: packet.messageID)
						if delegate?.send(packet: ack) ?? false  == false {
							unsentAcks[packet.messageID] = ack
						}
						break
					case .exactlyOnce:
						let ack = MQTTPublishRecPacket(messageID: packet.messageID)
						mutex.writing {unacknowledgedQos2Rel[packet.messageID] = packet}
						if qos2Mode == .lowLatency {
							issue(packet: packet)
						}
						if delegate?.send(packet: ack) ?? false == false {
							mutex.writing{unsentAcks[packet.messageID] = ack}
						}
						// else do not issue
						break
				}
				return true
			case let packet as MQTTPublishRelPacket:
				let ack = MQTTPublishCompPacket(messageID: packet.messageID)
				if delegate?.send(packet: ack) ?? false == false {
					mutex.writing{unsentAcks[packet.messageID] = ack}
				}
				if let element = mutex.writing({unacknowledgedQos2Rel.removeValue(forKey:packet.messageID)}) {
					if qos2Mode == .assured {
						issue(packet: element)
					}
				}
				return true
			default:
				return false
		}
	}
}
