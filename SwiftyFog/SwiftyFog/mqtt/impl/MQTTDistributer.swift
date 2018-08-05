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
	func mqtt(unhandledMessage: MQTTMessage)
}

final class MQTTDistributor {
	private let host: String
	private let issuer: MQTTPacketIssuer
	private let qos2Mode: Qos2Mode
	
	private struct OrderedEntry {
		let token: UInt64
		private let path: MQTTTopicPattern
		private let action: (MQTTMessage)->()
		
		init(_ path: String, _ token: UInt64, _ action: @escaping (MQTTMessage)->()) {
			self.path = MQTTTopicPattern(path: path)
			self.token = token
			self.action = action
		}
		
		func action(for topic: String) -> ((MQTTMessage)->())? {
			return path.matches(full: topic) == .success ? action : nil
		}
	}
	
	weak var delegate: MQTTDistributorDelegate?
	
	private let mutex = ReadWriteMutex()
	private var token: UInt64 = 0
	private var registeredPaths = [OrderedEntry]()
	
	private var deferredPacket = [UInt16:MQTTPublishPacket]()
	
	init(host: String, issuer: MQTTPacketIssuer, qos2Mode: Qos2Mode) {
		self.host = host
		self.issuer = issuer
		self.qos2Mode = qos2Mode
	}
	
	func connected(cleanSession: Bool, present: Bool, initial: Bool) {
	}
	
	func disconnected(cleanSession: Bool, stopped: Bool) {
		if cleanSession == true {
			mutex.writing {
				deferredPacket.removeAll()
			}
		}
	}
	
	func registerTopic(path: String, action: @escaping (MQTTMessage)->()) -> MQTTRegistration {
		return mutex.writing {
			token += 1
			let entity = MQTTDistributor.OrderedEntry(path, token, action)
			registeredPaths.append(entity)
			let registration = MQTTRegistration(token: token, path: path)
			registration.distributor = self
			return registration
		}
	}
	
	fileprivate func unregisterTopic(token: UInt64, path: String) {
		return mutex.writing {
			for i in (0..<registeredPaths.count).reversed() {
				if registeredPaths[i].token == token {
					registeredPaths.remove(at: i)
					return
				}
			}
		}
	}
	
	private func issue(packet: MQTTPublishPacket) {
		var actions = [(MQTTMessage)->()]()
		let msg = MQTTMessage(host: self.host, publishPacket: packet)
		let topic = String(packet.message.topic)
		mutex.reading {
			registeredPaths.forEach {
				if let action = $0.action(for: topic) {
					actions.append(action)
				}
			}
		}
		actions.forEach { $0(msg) }
		if actions.count == 0 {
			delegate?.mqtt(unhandledMessage: msg)
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
						issuer.send(packet: ack, sent: nil)
						break
					case .exactlyOnce:
						if qos2Mode == .lowLatency {
							issue(packet: packet)
						}
						else {
							mutex.writing {deferredPacket[packet.messageID] = packet}
						}
						let rec = MQTTPublishRecPacket(messageID: packet.messageID)
						issuer.send(packet: rec, sent: nil)
						break
				}
				return true
			case let rel as MQTTPublishRelPacket:
				let comp = MQTTPublishCompPacket(messageID: rel.messageID)
				issuer.received(acknolwedgment: rel, releaseId: false)
				issuer.send(packet: comp, sent: nil)
				if qos2Mode == .assured {
					if let element = mutex.writing({deferredPacket.removeValue(forKey:rel.messageID)}) {
						issue(packet: element)
					}
				}
				return true
			default:
				return false
		}
	}
}
