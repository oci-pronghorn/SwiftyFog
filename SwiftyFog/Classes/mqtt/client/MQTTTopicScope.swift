//
//  MQTTTopicScope.swift
//  Pods-SwiftyFog_Example
//
//  Created by David Giovannini on 8/19/17.
//

import Foundation

class MQTTTopicScope: MQTTBridge {
	var base: MQTTBridge
	let root: String
	
	func createBridge(rooted: String) -> MQTTBridge {
		return MQTTTopicScope(base: self.base, root: self.root + "/" + rooted)
	}
	
	init(base: MQTTBridge, root: String) {
		self.base = base
		self.root = root + "/"
	}
	
	func subscribe(topics: [(String, MQTTQoS)], completion: ((Bool)->())?) -> MQTTSubscription {
		let qualified = topics.map {
			return (
				$0.0.hasPrefix("/") ? String($0.0.suffix(1)) : self.root + $0.0,
				$0.1
			)
		}
		return base.subscribe(topics: qualified, completion: completion)
	}

	func publish(_ pubMsg: MQTTPubMsg, completion: ((Bool)->())?) {
		let topic = String(pubMsg.topic)
		let resolved = topic.hasPrefix("/") ? String(topic.suffix(1)) : self.root + topic
		let scoped = MQTTPubMsg(topic: resolved, payload: pubMsg.payload, retain: pubMsg.retain, qos: pubMsg.qos)
		base.publish(scoped)
	}
	
	func registerTopic(path: String, action: @escaping (MQTTMessage)->()) -> MQTTRegistration {
		let resolved = path.hasPrefix("/") ? String(path.suffix(1)) : self.root + path
		return base.registerTopic(path: resolved, action: action)
	}
}
