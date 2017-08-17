//
//  MQTTBridge.swift
//  Pods-SwiftyFog_Example
//
//  Created by David Giovannini on 8/15/17.
//

import Foundation

public protocol MQTTBridge {
	func publish(_ pubMsg: MQTTPubMsg, completion: ((Bool)->())?)
	
	func subscribe(topics: [(String, MQTTQoS)], completion: ((Bool)->())?) -> MQTTSubscription
	
	func registerTopic(path: String, action: @escaping (MQTTMessage)->()) -> MQTTRegistration
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
