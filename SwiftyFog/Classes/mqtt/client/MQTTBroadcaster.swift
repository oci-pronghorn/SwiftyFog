//
//  MQTTBroadcaster.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/20/17.
//

import Foundation

public final class MQTTBroadcaster {
	private let registration: [MQTTRegistration]
	private let subscription: MQTTSubscription!
	
	fileprivate init(registration: [MQTTRegistration], subscription: MQTTSubscription) {
		self.registration = registration
		self.subscription = subscription
	}
}

// MQTTBroadcaster is a full declarative registration for both subscription and distribution
/*
			broadcaster = mqtt.broadcast(to: self, queue: DispatchQueue.main, topics: [
				("powered", .atLeastOnce, Engine.receivePower),
				("calibrated", .atLeastOnce, Engine.receiveCalibration)
			])
*/
public extension MQTTBridge {
	public func broadcast<T: AnyObject>(to l: T, queue: DispatchQueue? = nil, topics: [(String, MQTTQoS, (T)->((MQTTMessage)->()))], completion: ((Bool)->())? = nil) -> MQTTBroadcaster {
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
			subscription: subscribe(topics: topics.map {e in (e.0, e.1)}, completion: completion)
		)
	}
}
