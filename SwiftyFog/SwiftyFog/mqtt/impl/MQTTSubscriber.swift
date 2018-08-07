//
//  MQTTSubscriber.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/12/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

public enum MQTTSubscriptionStatus : CustomStringConvertible {
	case subPending([(String, MQTTQoS)])
	case subscribed([(String, MQTTQoS, MQTTQoS?)])
	case unsubPending([String])
	case unsubFailed([String])
	case unsubscribed([String])
	case suspended([String])
	
	public var description: String {
		switch self {
		case .subPending(let list):
			return list.reduce("pending [\n", { (a, v) in
				return a + "\t'\(v.0)' <\(v.1)>\n"
			}) + "]"
		case .subscribed(let list):
			return list.reduce("subscribed [\n", { (a, v) in
				return a + "\t'\(v.0)' <\(v.1)> -> <\(v.2?.description ?? "")>\n"
			}) + "]"
		case .unsubPending(let list):
			return list.reduce("unsubscribe pending [\n", { (a, v) in
				return a + "\t'\(v)'\n"
			}) + "]"
		case .unsubFailed(let list):
			return list.reduce("failed unsubscribe [\n", { (a, v) in
				return a + "\t'\(v)'\n"
			}) + "]"
		case .unsubscribed(let list):
			return list.reduce("unsubscribed [\n", { (a, v) in
				return a + "\t'\(v)'\n"
			}) + "]"
		case .suspended(let list):
			return list.reduce("suspended [\n", { (a, v) in
				return a + "\t'\(v)'\n"
			}) + "]"
		}
	}
}

public typealias SubscriptionAcknowledged = (MQTTSubscriptionStatus)->()

public struct MQTTSubscriptionDetail: CustomStringConvertible  {
	public let token: UInt64
	public let topics: [(String, MQTTQoS)]
	fileprivate let ack: SubscriptionAcknowledged?
	
	fileprivate init(_ token: UInt64, _ topics: [(String, MQTTQoS)], _ ack: SubscriptionAcknowledged?) {
		self.token = token
		self.topics = topics
		self.ack = ack
	}
	
	public var description: String {
		return "#\(token) \(topics)"
	}
}

public final class MQTTSubscription: CustomStringConvertible {
	fileprivate weak var subscriber: MQTTSubscriber? = nil
	public let detail: MQTTSubscriptionDetail
	
	fileprivate init(token: UInt64, topics: [(String, MQTTQoS)], ack: SubscriptionAcknowledged?) {
		self.detail = MQTTSubscriptionDetail(token, topics, ack)
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
	private var knownSubscriptions = [UInt64 : MQTTSubscriptionDetail]()
	private var deferredSubscriptions = [UInt16 : MQTTSubscriptionDetail]()
	private var deferredUnSubscriptions = [UInt16 : MQTTSubscriptionDetail]()
		
	init(issuer: MQTTPacketIssuer) {
		self.issuer = issuer
	}
	
	func connected(cleanSession: Bool, present: Bool, initial: Bool) -> [MQTTSubscription] {
		return mutex.writing {
			// If we are reconnecting then start subscriptions over
			// If we have not connected yet subscriptions should be queued in issuer
			if initial == false {
				for token in knownSubscriptions.keys.sorted() {
					if let subscription = knownSubscriptions[token] {
						startSubscription(subscription)
					}
					else {
						knownSubscriptions.removeValue(forKey: token)
					}
				}
			}
			else if cleanSession == false && present == true {
				// TODO: return recreated last known subscriptions from file
				// if not clean and session present then likely we will need to
				// recreated RAII subscription objects that unless dealt with will
				// unsubscribe.
			}
			return []
		}
	}
	
	func disconnected(cleanSession: Bool, stopped: Bool) {
		mutex.writing {
			// Inform ack callbacks
			for token in knownSubscriptions.keys.sorted().reversed() {
				if let subscription = knownSubscriptions[token] {
					subscription.ack?(.suspended(subscription.topics.map{$0.0}))
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
			let subscription = MQTTSubscription(token: token, topics: topics, ack: acknowledged)
			subscription.subscriber = self
			knownSubscriptions[token] = subscription.detail
			startSubscription(subscription.detail)
			return subscription
		}
	}
	
	private func startSubscription(_ subscription: MQTTSubscriptionDetail) {
		// In Mutex already
		subscription.ack?(.subPending(subscription.topics))
		issuer.send(packet: {MQTTSubPacket(topics: subscription.topics, messageID: $0)})  { [weak self] p, s in
			if (s) {
				self?.mutex.writing { self?.deferredSubscriptions[p.messageID] = subscription }
			}
			else {
				subscription.ack?(.subscribed(subscription.topics.map { ($0.0, $0.1, nil as MQTTQoS?) }))
			}
		}
	}
	
	fileprivate func unsubscribe(_ subscription: MQTTSubscriptionDetail) {
		mutex.writing {
			knownSubscriptions[subscription.token] = nil
			let topicStrings = subscription.topics.map({$0.0})
			subscription.ack?(.unsubPending(subscription.topics.map{$0.0}))
			issuer.send(packet: {MQTTUnsubPacket(topics: topicStrings, messageID: $0)}) { [weak self] p, s in
				if (s) {
					self?.mutex.writing { self?.deferredUnSubscriptions[p.messageID] = subscription }
				}
				else {
					subscription.ack?(.unsubFailed(subscription.topics.map{$0.0}))
				}
			}
		}
	}
	
	func receive(packet: MQTTPacket) -> Bool {
		switch packet {
			case let packet as MQTTSubAckPacket:
				if let element = mutex.writing({deferredSubscriptions.removeValue(forKey:packet.messageID)}) {
					element.ack?(.subscribed(zip(element.topics, packet.maxQoS).map { ($0.0.0, $0.0.1, $0.1) }))
				}
				issuer.received(acknolwedgment: packet, releaseId: true)
				return true
			case let packet as MQTTUnsubAckPacket:
				if let element = mutex.writing({deferredUnSubscriptions.removeValue(forKey:packet.messageID)}) {
					element.ack?(.unsubscribed(element.topics.map { $0.0 }))
				}
				issuer.received(acknolwedgment: packet, releaseId: true)
				return true
			default:
				return false
		}
	}
}
