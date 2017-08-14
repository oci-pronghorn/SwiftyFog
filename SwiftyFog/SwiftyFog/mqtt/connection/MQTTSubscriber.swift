//
//  MQTTSubscriber.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/12/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

public protocol MQTTSubscriptionDelegate: class {
	func send(packet: MQTTPacket) -> Bool
}

public class MQTTSubscription {
	fileprivate weak var subscriber: MQTTSubscriber? = nil
	fileprivate let token: UInt64
	public let topics: [String]
	
	fileprivate init(token: UInt64, topics: [String]) {
		self.token = token
		self.topics = topics
	}
	
	deinit {
		subscriber?.unsubscribe(token: token, topics: topics)
	}
}

public class MQTTSubscriber {
	private let idSource: MQTTMessageIdSource
	private var token: UInt64 = 0
	//private var unsentSubscriptions = [UInt64: ([String: MQTTQoS],((Bool)->())?)]()
	private var unacknowledgedSubscriptions = [UInt16: (MQTTSubPacket,((Bool)->())?)]()
	private var unacknowledgedUnsubscriptions = [UInt16: (MQTTUnsubPacket,((Bool)->())?)]()
	
	public weak var delegate: MQTTSubscriptionDelegate?
	
	public init(idSource: MQTTMessageIdSource) {
		self.idSource = idSource
	}
	
	public func connected(cleanSession: Bool) {
		// resubscribe
	}
	
	public func disconnected(cleanSession: Bool, final: Bool) {
	}

	public func subscribe(topics: [String: MQTTQoS], completion: ((Bool)->())?) -> MQTTSubscription {
		token += 1
		let subscription = MQTTSubscription(token: token, topics: Array(topics.keys))
		subscription.subscriber = self
		
        let packet = MQTTSubPacket(topics: topics, messageID: idSource.fetch())
		unacknowledgedSubscriptions[packet.messageID] = (packet, completion)
		
        if delegate?.send(packet: packet) ?? false == false {
			unacknowledgedSubscriptions.removeValue(forKey: packet.messageID)
			//unsentSubscriptions[token] = ((topics, completion))
			return subscription
        }
		
		return subscription
	}
	
	fileprivate func unsubscribe(token: UInt64, topics: [String]) {
        let packet = MQTTUnsubPacket(topics: topics, messageID: idSource.fetch())
		unacknowledgedUnsubscriptions[packet.messageID] = (packet, nil)
        let _ = delegate?.send(packet: packet)
	}
	
	public func receive(packet: MQTTPacket) -> Bool {
		switch packet {
			case let packet as MQTTSubAckPacket:
				if let element = unacknowledgedSubscriptions.removeValue(forKey:packet.messageID) {
					idSource.release(id: element.0.messageID)
					element.1?(true)
				}
				return true
			case let packet as MQTTUnsubAckPacket:
				if let element = unacknowledgedUnsubscriptions.removeValue(forKey:packet.messageID) {
					idSource.release(id: element.0.messageID)
					element.1?(true)
				}
				return true
			default:
				return false
		}
	}
}
