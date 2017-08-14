//
//  MQTTDistributer.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/13/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

public class MQTTRegistration {
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

public protocol MQTTDistributorDelegate: class {
	func send(packet: MQTTPacket) -> Bool
}

public class MQTTDistributor {
	private let idSource: MQTTMessageIdSource
	private var unacknowledgedQos2Rel = [UInt16:MQTTPublishPacket]()
	
	public weak var delegate: MQTTDistributorDelegate?
	
	// TODO: threadsafety with state
	private let mutex = ReadWriteMutex()
	
	public init(idSource: MQTTMessageIdSource) {
		self.idSource = idSource
	}
	
	public func connected(cleanSession: Bool) {
	}
	
	public func disconnected(cleanSession: Bool, final: Bool) {
	}
	
	public func registerTopic(path: String, action: ()->()) {
	}
	
	fileprivate func unregisterTopic(token: UInt64, path: String) {
	}
	
	private func issue(packet: MQTTPublishPacket) {
		// TODO: check for partial path registrations and execute actions
	}

	public func receive(packet: MQTTPacket) -> Bool {
		switch packet {
			case let packet as MQTTPublishPacket:
				switch packet.message.QoS {
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
						unacknowledgedQos2Rel[packet.messageID] = packet
						if delegate?.send(packet: ack) ?? false == false {
							unacknowledgedQos2Rel.removeValue(forKey: packet.messageID)
						}
						break
				}
				return true
			case let packet as MQTTPublishRelPacket:
				if let element = unacknowledgedQos2Rel.removeValue(forKey:packet.messageID) {
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
