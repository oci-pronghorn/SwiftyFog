//
//  Train.swift
//  TrainControl
//
//  Created by David Giovannini on 8/28/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation
import SwiftyFog_iOS

public typealias TrainRational = FogRational<Int32>

public protocol TrainDelegate: class {
	func train(alive: Bool)
    func train(faults: MotionFaults, _ asserted: Bool)
}

public class Train: FogFeedbackModel {
	private var broadcaster: MQTTBroadcaster?
    private var fault: FogFeedbackValue<MotionFaults>
	
	public weak var delegate: TrainDelegate?
	
    public var mqtt: MQTTBridge! {
		didSet {
			broadcaster = mqtt.broadcast(to: self, queue: DispatchQueue.main, topics: [
				("lifecycle/feedback", .atLeastOnce, Train.feedbackLifecycle),
                ("fault/feedback", .atLeastOnce, Train.feedbackFault)
			]) { listener, status in
				print("***Subscription Status: \(status)")
			}
		}
    }
	
    init() {
        self.fault = FogFeedbackValue(MotionFaults())
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
    
    public func controlFault() {
        mqtt.publish(MQTTMessage(topic: "fault/control"))
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
    
    private func feedbackFault(msg: MQTTMessage) {
        self.fault.receive(msg.payload.fogExtract()) { value, asserted in
            delegate?.train(faults: value, asserted)
        }
    }
}
