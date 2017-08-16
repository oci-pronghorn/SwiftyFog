//
//  MQTTBridge.swift
//  Pods-SwiftyFog_Example
//
//  Created by David Giovannini on 8/15/17.
//

import Foundation

public protocol MQTTBridge {
	func publish(_ pubMsg: MQTTPubMsg, retry: MQTTPublishRetry, completion: ((Bool)->())?)
	
	func subscribe(topics: [(String, MQTTQoS)], completion: ((Bool)->())?) -> MQTTSubscription
	
	func registerTopic(path: String, action: @escaping (MQTTMessage)->()) -> MQTTRegistration
}

public extension MQTTBridge {
	public func publish(_ pubMsg: MQTTPubMsg) {
		return publish(pubMsg, retry: MQTTPublishRetry(), completion: nil)
	}
	
	public func publish(_ pubMsg: MQTTPubMsg, completion: ((Bool)->())?) {
		return publish(pubMsg, retry: MQTTPublishRetry(), completion: completion)
	}
	
	public func subscribe(topics: [(String, MQTTQoS)]) -> MQTTSubscription {
		return subscribe(topics: topics, completion: nil)
	}
}
