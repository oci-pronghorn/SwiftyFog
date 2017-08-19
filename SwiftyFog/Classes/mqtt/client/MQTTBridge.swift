//
//  MQTTBridge.swift
//  Pods-SwiftyFog_Example
//
//  Created by David Giovannini on 8/15/17.
//

import Foundation

public protocol MQTTBridge {
	// If pubMsg.topic begins with '$' it will be used as an absolute path
	// Otherwise fullpath is built from the bridge chain
	func publish(_ pubMsg: MQTTPubMsg, completion: ((Bool)->())?)
	
	// If topic.0 begins with '$' it will be used as an absolute path
	// Otherwise fullpath is built from the bridge chain
	// All MQTT wildcards work according to specifications
	func subscribe(topics: [(String, MQTTQoS)], completion: ((Bool)->())?) -> MQTTSubscription
	
	// If path begins with '$' it will be used as an absolute path
	// Otherwise fullpath is built from the bridge chain
	// The path does not support subscription type wild cards
	func registerTopic(path: String, action: @escaping (MQTTMessage)->()) -> MQTTRegistration
	
	// Create a new MQTTBridge relative to this
	func createBridge(subPath: String) -> MQTTBridge
}

public extension MQTTBridge {
	public func publish(_ pubMsg: MQTTPubMsg) {
		return publish(pubMsg, completion: nil)
	}
	
	public func subscribe(topics: [(String, MQTTQoS)]) -> MQTTSubscription {
		return subscribe(topics: topics, completion: nil)
	}
	
	public func registerTopics(_ topicActions: [(String, (MQTTMessage)->())]) -> [MQTTRegistration] {
		return topicActions.map { registerTopic(path: $0.0, action: $0.1) }
	}
}
