//
//  MQTTBroadcaster.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/20/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
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
// The optional acknowledge lambda resolves the weak reference to the listener (self in this case)
/*
			broadcaster = mqtt.broadcast(to: self, queue: DispatchQueue.main, topics: [
				("power/feedback", .atMostOnce, Engine.feedbackPower),
				("calibration/feedback", .atMostOnce, Engine.feedbackCalibration)
			]) { listener, _, _ in
				listener.askForFeedback()
			}
*/

public typealias MQTTBroadcastAcknowledged<T: AnyObject> = (T, Int, [(String, MQTTQoS, MQTTQoS?)])->()

public extension MQTTBridge {
	public func broadcast<T: AnyObject>(to l: T, queue: DispatchQueue? = nil, topics: [(String, MQTTQoS, (T)->((MQTTMessage)->()))], acknowledged: MQTTBroadcastAcknowledged<T>? = nil) -> MQTTBroadcaster {
	
		let subAcknowledged: SubscriptionAcknowledged? = acknowledged == nil ? nil :
			{ [weak l] iter, success in
				if let l = l {
					acknowledged!(l, iter, success)
				}
			}
	
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
			subscription: subscribe(topics: topics.map {e in (e.0, e.1)}, acknowledged: subAcknowledged)
		)
	}
}
