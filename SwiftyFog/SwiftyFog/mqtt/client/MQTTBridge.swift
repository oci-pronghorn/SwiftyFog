//
//  MQTTBridge.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/15/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

// MQTTSubscription and MQTTRegistration are RAII owners of the subscribe and
// register requests. When all references goes to nil, the unsubscribe/unregister
// happens.
// If the referance is reassigned it is important to note the unaction of the old
// value happens after the action of the new value. If the reference is reused
// you may choose to set it to nil before the assignement.

public protocol MQTTBridge {
	
	// If pubMsg.topic begins with '$' it will be used as an absolute path
	// Otherwise fullpath is built from the bridge chain
	func publish(_ pubMsg: MQTTMessage, completion: ((Bool)->())?)
	
	// If topic.0 begins with '$' it will be used as an absolute path
	// Otherwise fullpath is built from the bridge chain
	// All MQTT wildcards work according to specifications
	func subscribe(topics: [(String, MQTTQoS)], acknowledged: SubscriptionAcknowledged?) -> MQTTSubscription
	
	// If path begins with '$' it will be used as an absolute path
	// Otherwise fullpath is built from the bridge chain
	// The path does not support subscription type wild cards
	func register(topic: String, action: @escaping (MQTTMessage)->()) -> MQTTRegistration
	
	// Create a new MQTTBridge relative to this
	func createBridge(subPath: String) -> MQTTBridge
}

public extension MQTTBridge {
	public func publish(_ pubMsg: MQTTMessage) {
		return publish(pubMsg, completion: nil)
	}
	
	public func subscribe(topics: [(String, MQTTQoS)]) -> MQTTSubscription {
		return subscribe(topics: topics, acknowledged: nil)
	}
	
	public func register(topics: [(String, (MQTTMessage)->())]) -> [MQTTRegistration] {
		return topics.map { register(topic: $0.0, action: $0.1) }
	}
}
