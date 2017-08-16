//
//  MQTTSubscriber.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/12/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

public enum MQTTSubscriptionStatus: String {
	case dropped
	case subPending
	case subscribed
	case unsubPending
	case unsubFailed
	case unsubscribed
	case suspended
}

protocol MQTTSubscriptionDelegate: class {
	func send(packet: MQTTPacket) -> Bool
	func subscriptionChanged(subscription: MQTTSubscription, status: MQTTSubscriptionStatus)
}

public class MQTTSubscription: CustomStringConvertible {
	fileprivate weak var subscriber: MQTTSubscriber? = nil
	public let token: UInt64
	public let topics: [String: MQTTQoS]
	
	fileprivate init(token: UInt64, topics: [String: MQTTQoS]) {
		self.token = token
		self.topics = topics
	}
	
	deinit {
		subscriber?.unsubscribe(token: token, topics: topics)
	}
	
	public var description: String {
		return "\(token)"
	}
}

final class MQTTSubscriber {
	private let idSource: MQTTMessageIdSource
	
	private let mutex = ReadWriteMutex()
	private var token: UInt64 = 0
	private var unacknowledgedSubscriptions = [UInt16: (MQTTSubPacket,UInt64,((Bool)->())?)]()
	private var unacknowledgedUnsubscriptions = [UInt16: (MQTTUnsubPacket,UInt64,((Bool)->())?)]()
	private var knownSubscriptions = [UInt64: WeakHandle<MQTTSubscription>]()
	
	weak var delegate: MQTTSubscriptionDelegate?
	
	init(idSource: MQTTMessageIdSource) {
		self.idSource = idSource
	}
	
	func connected(cleanSession: Bool) {
		// TODO: is this necessary when clean is false
		mutex.writing {
			for token in knownSubscriptions.keys.sorted() {
				if let subscription = knownSubscriptions[token]?.value {
					startSubscription(subscription: subscription, completion: nil)
				}
				else {
					knownSubscriptions.removeValue(forKey: token)
				}
			}
		}
	}
	
	func disconnected(cleanSession: Bool, final: Bool) {
		mutex.writing {
			unacknowledgedSubscriptions.removeAll()
			unacknowledgedUnsubscriptions.removeAll()
			for token in knownSubscriptions.keys.sorted().reversed() {
				if let subscription = knownSubscriptions[token]?.value {
					delegate?.subscriptionChanged(subscription: subscription, status: final ? .unsubscribed : .suspended)
				}
				else {
					knownSubscriptions.removeValue(forKey: token)
				}
			}
		}
	}

	func subscribe(topics: [String: MQTTQoS], completion: ((Bool)->())?) -> MQTTSubscription {
		return mutex.writing {
			token += 1
			let subscription = MQTTSubscription(token: token, topics: topics)
			subscription.subscriber = self
			knownSubscriptions[token] = WeakHandle(object: subscription)
			startSubscription(subscription: subscription, completion: completion)
			return subscription
		}
	}
	
	private func startSubscription(subscription: MQTTSubscription, completion: ((Bool)->())?) {
		let messageId = idSource.fetch()
        let packet = MQTTSubPacket(topics: subscription.topics, messageID: messageId)
		unacknowledgedSubscriptions[packet.messageID] = (packet, subscription.token, completion)
		delegate?.subscriptionChanged(subscription: subscription, status: .subPending)
        if delegate?.send(packet: packet) ?? false == false {
			delegate?.subscriptionChanged(subscription: subscription, status: .dropped)
			unacknowledgedSubscriptions.removeValue(forKey: messageId)
        }
	}
	
	fileprivate func unsubscribe(token: UInt64, topics: [String: MQTTQoS]) {
		mutex.writing {
			knownSubscriptions.removeValue(forKey: token)
			let packet = MQTTUnsubPacket(topics: Array(topics.keys), messageID: idSource.fetch())
			unacknowledgedUnsubscriptions[packet.messageID] = (packet, token, nil)
			let copy = MQTTSubscription(token: token, topics: topics)
			delegate?.subscriptionChanged(subscription: copy, status: .unsubPending)
			if delegate?.send(packet: packet) ?? false == false {
				delegate?.subscriptionChanged(subscription: copy, status: .unsubFailed)
				unacknowledgedUnsubscriptions.removeValue(forKey: packet.messageID)
			}
		}
	}
	
	func receive(packet: MQTTPacket) -> Bool {
		switch packet {
			case let packet as MQTTSubAckPacket:
				idSource.free(id: packet.messageID)
				if let element = mutex.writing({unacknowledgedSubscriptions.removeValue(forKey:packet.messageID)}) {
					if let subscription = knownSubscriptions[element.1]?.value {
						delegate?.subscriptionChanged(subscription: subscription, status: .subscribed)
					}
					element.2?(true)
				}
				return true
			case let packet as MQTTUnsubAckPacket:
				idSource.free(id: packet.messageID)
				if let element = mutex.writing({unacknowledgedUnsubscriptions.removeValue(forKey:packet.messageID)}) {
					if let subscription = knownSubscriptions[element.1]?.value {
						delegate?.subscriptionChanged(subscription: subscription, status: .unsubscribed)
					}
					element.2?(true)
				}
				return true
			default:
				return false
		}
	}
}
