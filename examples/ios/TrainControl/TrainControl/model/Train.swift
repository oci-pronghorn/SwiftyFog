//
//  Train.swift
//  TrainControl
//
//  Created by David Giovannini on 8/28/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation
#if os(iOS)
import SwiftyFog_iOS
#elseif os(watchOS)
import SwiftFog_watch
#endif

public typealias TrainRational = FogRational<Int32>

public protocol TrainDelegate: class, SubscriptionLogging {
	func train(alive: Bool)
    func train(faults: MotionFaults, _ asserted: Bool)
}

public class Train: FogFeedbackModel {
	private var broadcaster: MQTTBroadcaster?
    private var fault: FogFeedbackValue<MotionFaults>
	
	public weak var delegate: TrainDelegate?
	
    public var mqtt: MQTTBridge! {
		didSet {
			broadcaster.assign(mqtt.broadcast(to: self, queue: DispatchQueue.main, topics: [
				("lifecycle/feedback", .atLeastOnce, Train.feedbackLifecycle),
                ("fault/feedback", .atLeastOnce, Train.feedbackFault)
			]) {[weak self] (_, status) in self?.delegate?.onSubscriptionAck(status: status)})
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
	
	public func askForFeedback() {
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
