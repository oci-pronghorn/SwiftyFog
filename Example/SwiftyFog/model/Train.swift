//
//  Train.swift
//  SwiftyFog_Example
//
//  Created by David Giovannini on 8/28/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation
import SwiftyFog

public protocol TrainDelegate: class {
	func train(alive: Bool)
}

public class Train: FogFeedbackModel {
	private var broadcaster: MQTTBroadcaster?
	
	public weak var delegate: TrainDelegate?
	
    public var mqtt: MQTTBridge! {
		didSet {
			broadcaster = mqtt.broadcast(to: self, queue: DispatchQueue.main, topics: [
				("lifecycle/feedback", .atLeastOnce, Train.feedbackLifecycle)
			]) { listener, status in
				if case .subscribed(_) = status {
					listener.askForFeedback()
				}
			}
		}
    }
	
    init() {
	}
	
	public func reset() {
	}
	
	public var hasFeedback: Bool {
		return true
	}
	
	public func assertValues() {
	}
	
	public func controlShutdown() {
		mqtt.publish(MQTTMessage(topic: "lifecycle/control/shutdown", qos: .atMostOnce))
	}
	
	private func askForFeedback() {
		mqtt.publish(MQTTMessage(topic: "feedback", qos: .atLeastOnce))
	}
	
	private func feedbackLifecycle(msg: MQTTMessage) {
		let alive: Bool = msg.payload.fogExtract()
		delegate?.train(alive: alive)
		if alive {
			askForFeedback()
		}
	}
}
