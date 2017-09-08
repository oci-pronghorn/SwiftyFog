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

public typealias SubscriptionAcknowledged = (Int, [(String, MQTTQoS, MQTTQoS?)])->()

public struct MQTTSubscriptionDetail: CustomStringConvertible  {
	public let token: UInt64
	public let topics: [(String, MQTTQoS)]
	
	fileprivate init(_ token: UInt64, _ topics: [(String, MQTTQoS)]) {
		self.token = token
		self.topics = topics
	}
	
	public var description: String {
		return "#\(token) \(topics)"
	}
}

protocol MQTTSubscriptionDelegate: class {
	func mqtt(subscription: MQTTSubscriptionDetail, changed: MQTTSubscriptionStatus)
}

public final class MQTTSubscription: CustomStringConvertible {
	fileprivate weak var subscriber: MQTTSubscriber? = nil
	public let detail: MQTTSubscriptionDetail
	
	fileprivate init(token: UInt64, topics: [(String, MQTTQoS)]) {
		self.detail = MQTTSubscriptionDetail(token, topics)
	}
	
	deinit {
		subscriber?.unsubscribe(detail)
	}
	
	public var description: String {
		return detail.description
	}
}

final class MQTTSubscriber {
	private let issuer: MQTTPacketIssuer
	
	private let mutex = ReadWriteMutex()
	private var token: UInt64 = 0
	private var knownSubscriptions = [UInt64 : (MQTTSubscriptionDetail, SubscriptionAcknowledged?)]()
	private var deferredSubscriptions = [UInt16 : (MQTTSubscriptionDetail, SubscriptionAcknowledged?)]()
	private var deferredUnSubscriptions = [UInt16 : (MQTTSubscriptionDetail, ((Bool)->())?)]()
	
	weak var delegate: MQTTSubscriptionDelegate?
	
	init(issuer: MQTTPacketIssuer) {
		self.issuer = issuer
	}
	
	func connected(cleanSession: Bool, present: Bool, initial: Bool) {
		mutex.writing {
			// If we are reconnecting then start subscriptions over
			// If we have not connected yet subscriptions should be queued in issuer
			if initial == false {
				for token in knownSubscriptions.keys.sorted() {
					if let subscription = knownSubscriptions[token] {
						startSubscription(subscription.0, subscription.1)
					}
					else {
						knownSubscriptions.removeValue(forKey: token)
					}
				}
			}
			else if cleanSession == false && present == true {
				// TODO: return recreated last known subscriptions from file
			}
		}
	}
	
	func disconnected(cleanSession: Bool, stopped: Bool) {
		mutex.writing {
			// Inform delegate the subscriptions have been suspended
			for token in knownSubscriptions.keys.sorted().reversed() {
				if let subscription = knownSubscriptions[token] {
					delegate?.mqtt(subscription: subscription.0, changed: .suspended)
				}
				// cleanup if we can
				else {
					knownSubscriptions.removeValue(forKey: token)
				}
			}
		}
	}

	func subscribe(topics: [(String, MQTTQoS)], acknowledged: SubscriptionAcknowledged?) -> MQTTSubscription {
		return mutex.writing {
			token += 1
			let subscription = MQTTSubscription(token: token, topics: topics)
			subscription.subscriber = self
			knownSubscriptions[token] = (subscription.detail, acknowledged)
			startSubscription(subscription.detail, acknowledged)
			return subscription
		}
	}
	
	private func startSubscription(_ subscription: MQTTSubscriptionDetail, _ acknowledged: SubscriptionAcknowledged?) {
		// In Mutex already
		delegate?.mqtt(subscription: subscription, changed: .subPending)
		issuer.send(packet: {MQTTSubPacket(topics: subscription.topics, messageID: $0)}, expecting: .subAck)  { [weak self] p, s in
			if (s) {
				self?.mutex.writing { self?.deferredSubscriptions[p.messageID] = (subscription, acknowledged) }
			}
		}
	}
	
	fileprivate func unsubscribe(_ subscription: MQTTSubscriptionDetail) {
		mutex.writing {
			knownSubscriptions[subscription.token] = nil
			let topicStrings = subscription.topics.map({$0.0})
			delegate?.mqtt(subscription: subscription, changed: .unsubPending)
			issuer.send(packet: {MQTTUnsubPacket(topics: topicStrings, messageID: $0)}, expecting: .subAck) { [weak self] p, s in
				if (s) {
					self?.mutex.writing { self?.deferredUnSubscriptions[p.messageID] = (subscription, nil) }
				}
			}
		}
	}
	
	func receive(packet: MQTTPacket) -> Bool {
		switch packet {
			case let packet as MQTTSubAckPacket:
				if let element = mutex.writing({deferredSubscriptions.removeValue(forKey:packet.messageID)}) {
					delegate?.mqtt(subscription: element.0, changed: .subscribed)
					if let completion = element.1 {
						let result = zip(element.0.topics, packet.maxQoS).map { ($0.0.0, $0.0.1, $0.1) }
						// TODO return # of times been acknowledged
						completion(1, result)
					}
				}
				issuer.received(acknolwedgment: packet, releaseId: true)
				return true
			case let packet as MQTTUnsubAckPacket:
				if let element = mutex.writing({deferredUnSubscriptions.removeValue(forKey:packet.messageID)}) {
					delegate?.mqtt(subscription: element.0, changed: .unsubscribed)
					element.1?(true)
				}
				issuer.received(acknolwedgment: packet, releaseId: true)
				return true
			default:
				return false
		}
	}
}
