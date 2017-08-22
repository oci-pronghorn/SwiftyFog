//
//  MQTTBroadcaster.swift
//  Pods-SwiftyFog_Example
//
//  Created by David Giovannini on 8/20/17.
//

import Foundation

public class MQTTBroadcaster {
	private let registration: [MQTTRegistration]
	private let subscription: MQTTSubscription!
	
	fileprivate init(registration: [MQTTRegistration], subscription: MQTTSubscription) {
		self.registration = registration
		self.subscription = subscription
	}
}

public extension MQTTBridge {
	func broadcast<T: AnyObject>(to l: T, queue: DispatchQueue? = nil, topics: [(String, MQTTQoS, (T)->((MQTTMessage)->()))], completion: ((Bool)->())? = nil) -> MQTTBroadcaster {
		return MQTTBroadcaster(
			registration: register(topics: topics.map {
				e in (e.0, { [weak l] msg in
					if let l = l {
						if let q = queue {
							q.async{e.2(l)(msg)}
						}
						else {
							e.2(l)(msg)
						}
					}
				})
			}),
			subscription: subscribe(topics: topics.map {e in (e.0, e.1)},
			completion: completion))
	}
}
