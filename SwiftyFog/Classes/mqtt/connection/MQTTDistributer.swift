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
}

final class MQTTDistributor {
	private let idSource: MQTTMessageIdSource
	
	weak var delegate: MQTTDistributorDelegate?
	
	private let mutex = ReadWriteMutex()
	private var unacknowledgedQos2Rel = [UInt16:MQTTPublishPacket]()
	// TODO: use patial path of registration to activate specific actions
	private var singleAction: ((MQTTMessage)->())?
	
	init(idSource: MQTTMessageIdSource) {
		self.idSource = idSource
	}
	
	func connected(cleanSession: Bool) {
		if cleanSession == false {
			mutex.writing {
				for messageId in unacknowledgedQos2Rel.keys.sorted() {
					let packet = MQTTPublishRecPacket(messageID: messageId)
					let _ = delegate?.send(packet: packet)
				}
			}
		}
	}
	
	func disconnected(cleanSession: Bool, final: Bool) {
		if cleanSession == true {
			mutex.writing {
				unacknowledgedQos2Rel.removeAll()
			}
		}
	}
	
	func registerTopic(path: String, action: @escaping (MQTTMessage)->()) -> MQTTRegistration {
		singleAction = action
		return MQTTRegistration(token: 0, path: path)
	}
	
	fileprivate func unregisterTopic(token: UInt64, path: String) {
		singleAction = nil
	}
	
	private func issue(packet: MQTTPublishPacket) {
		// TODO: check for partial path registrations and execute actions
		singleAction?(MQTTMessage(publishPacket: packet))
	}

	func receive(packet: MQTTPacket) -> Bool {
		switch packet {
			case let packet as MQTTPublishPacket:
				switch packet.message.qos {
					case .atMostOnce:
						issue(packet: packet)
						break
					case .atLeastOnce:
						let ack = MQTTPublishAckPacket(messageID: packet.messageID)
						let _ = delegate?.send(packet: ack)
						issue(packet: packet)
						break
					case .exactlyOnce:
						let ack = MQTTPublishRecPacket(messageID: packet.messageID)
						mutex.writing {
							unacknowledgedQos2Rel[packet.messageID] = packet
						}
						if delegate?.send(packet: ack) ?? false == false {
							mutex.writing {
								unacknowledgedQos2Rel.removeValue(forKey: packet.messageID)
							}
						}
						break
				}
				return true
			case let packet as MQTTPublishRelPacket:
				if let element = mutex.writing({unacknowledgedQos2Rel.removeValue(forKey:packet.messageID)}) {
					let comp = MQTTPublishCompPacket(messageID: packet.messageID)
					let _ = delegate?.send(packet: comp)
					issue(packet: element)
				}
				return true
			default:
				return false
		}
	}
}
