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
	func send(packet: MQTTPacket) -> Bool
	func subscriptionChanged(subscription: MQTTSubscriptionDetail, status: MQTTSubscriptionStatus)
}

public class MQTTSubscription: CustomStringConvertible {
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
	private let idSource: MQTTMessageIdSource
	
	private let mutex = ReadWriteMutex()
	private var token: UInt64 = 0
	private var unacknowledgedSubscriptions = [UInt16: (MQTTSubPacket,MQTTSubscriptionDetail,((Bool)->())?)]()
	private var unacknowledgedUnsubscriptions = [UInt16: (MQTTUnsubPacket,MQTTSubscriptionDetail,((Bool)->())?)]()
	private var knownSubscriptions = [UInt64: MQTTSubscriptionDetail]()
	
	weak var delegate: MQTTSubscriptionDelegate?
	
	init(idSource: MQTTMessageIdSource) {
		self.idSource = idSource
	}
	
	func connected(cleanSession: Bool, present: Bool) {
		// TODO: If the application makes a subscription request before connection
		// we want to submit the pending subscriptions on connect.
		// If clean session is false the subscriptions are made again by the broker
		// with no communications.
		// But the subscriptions at shutdown are not necessarely the subscriptions we
		// want at startup.
		mutex.writing {
			for token in knownSubscriptions.keys.sorted() {
				if let subscription = knownSubscriptions[token] {
					startSubscription(subscription, nil)
				}
				else {
					knownSubscriptions.removeValue(forKey: token)
				}
			}
		}
	}
	
	func resendPulse() {
		mutex.reading {
			for key in unacknowledgedSubscriptions.keys.sorted() {
				let element = unacknowledgedSubscriptions[key]!
				sendSubscription(element.1, element.0)
			}
			for key in unacknowledgedUnsubscriptions.keys.sorted() {
				let element = unacknowledgedUnsubscriptions[key]!
				sendUnsubscription(element.1, element.0)
			}
		}
	}
	
	func disconnected(cleanSession: Bool, manual: Bool) {
		// TODO: What do we do if cleanSession == false
		mutex.writing {
			unacknowledgedSubscriptions.removeAll()
			unacknowledgedUnsubscriptions.removeAll()
			for token in knownSubscriptions.keys.sorted().reversed() {
				if let subscription = knownSubscriptions[token] {
					delegate?.subscriptionChanged(subscription: subscription, status: manual ? .unsubscribed : .suspended)
				}
				else {
					knownSubscriptions.removeValue(forKey: token)
				}
			}
		}
	}

	func subscribe(topics: [(String, MQTTQoS)], completion: ((Bool)->())?) -> MQTTSubscription {
		return mutex.writing {
			token += 1
			let subscription = MQTTSubscription(token: token, topics: topics)
			subscription.subscriber = self
			knownSubscriptions[token] = subscription.detail
			startSubscription(subscription.detail, completion)
			return subscription
		}
	}
	
	private func startSubscription(_ subscription: MQTTSubscriptionDetail, _ completion: ((Bool)->())?) {
		let messageId = idSource.fetch()
        let packet = MQTTSubPacket(topics: subscription.topics, messageID: messageId)
		unacknowledgedSubscriptions[packet.messageID] = (packet, subscription, completion)
		delegate?.subscriptionChanged(subscription: subscription, status: .subPending)
		sendSubscription(subscription, packet)
	}
	
	private func sendSubscription(_ subscription: MQTTSubscriptionDetail, _ packet: MQTTSubPacket) {
        if delegate?.send(packet: packet) ?? false == false {
			idSource.free(id: packet.messageID)
			delegate?.subscriptionChanged(subscription: subscription, status: .dropped)
			unacknowledgedSubscriptions.removeValue(forKey: packet.messageID)
        }
	}
	
	fileprivate func unsubscribe(_ subscription: MQTTSubscriptionDetail) {
		mutex.writing {
			knownSubscriptions[subscription.token] = nil
			startUnsubscription(subscription)
		}
	}
	
	private func startUnsubscription(_ subscription: MQTTSubscriptionDetail) {
		let packet = MQTTUnsubPacket(topics: subscription.topics.map({$0.0}), messageID: idSource.fetch())
		unacknowledgedUnsubscriptions[packet.messageID] = (packet, subscription, nil)
        delegate?.subscriptionChanged(subscription: subscription, status: .unsubPending)
		sendUnsubscription(subscription, packet)
	}
	
	private func sendUnsubscription(_ subscription: MQTTSubscriptionDetail, _ packet: MQTTUnsubPacket) {
		if delegate?.send(packet: packet) ?? false == false {
			idSource.free(id: packet.messageID)
			delegate?.subscriptionChanged(subscription: subscription, status: .unsubFailed)
			unacknowledgedUnsubscriptions.removeValue(forKey: packet.messageID)
		}
	}
	
	func receive(packet: MQTTPacket) -> Bool {
		switch packet {
			case let packet as MQTTSubAckPacket:
				idSource.free(id: packet.messageID)
				if let element = mutex.writing({unacknowledgedSubscriptions.removeValue(forKey:packet.messageID)}) {
					delegate?.subscriptionChanged(subscription: element.1, status: .subscribed)
					element.2?(true)
				}
				return true
			case let packet as MQTTUnsubAckPacket:
				idSource.free(id: packet.messageID)
				if let element = mutex.writing({unacknowledgedUnsubscriptions.removeValue(forKey:packet.messageID)}) {
					delegate?.subscriptionChanged(subscription: element.1, status: .unsubscribed)
					element.2?(true)
				}
				return true
			default:
				return false
		}
	}
}
