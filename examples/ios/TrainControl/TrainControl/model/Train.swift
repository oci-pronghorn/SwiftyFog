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
	func train(alive: Bool, named: String?)
    func train(faults: MotionFaults, _ asserted: Bool)
    func train(webHost: String?)
}

public class Train: FogFeedbackModel {
	private var broadcaster: MQTTBroadcaster?
    private var fault: FogFeedbackValue<MotionFaults>
	
	public weak var delegate: TrainDelegate?
	
    public var mqtt: MQTTBridge? {
		didSet {
			broadcaster.assign(mqtt?.broadcast(to: self, queue: DispatchQueue.main, topics: [
				("lifecycle/feedback", .atLeastOnce, Train.feedbackLifecycle),
                ("fault/feedback", .atLeastOnce, Train.feedbackFault),
                ("web/feedback", .atLeastOnce, Train.feedbackWeb),
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
		delegate?.train(webHost: nil)
	}
	
	public func controlShutdown() {
		mqtt?.publish(MQTTMessage(topic: "lifecycle/control/shutdown", qos: .atMostOnce))
	}
    
    public func controlFault() {
        mqtt?.publish(MQTTMessage(topic: "fault/control"))
    }
	
	public func askForFeedback() {
		mqtt?.publish(MQTTMessage(topic: "feedback", qos: .atLeastOnce))
	}
	
	private func feedbackLifecycle(msg: MQTTMessage) {
		var cursor:Int = 0
		let alive: Bool = msg.payload.fogExtract(&cursor)
		var displayName: String? = nil
		if alive {
			displayName = msg.payload.fogExtract(&cursor)
		}
		delegate?.train(alive: alive, named: displayName)
		if alive {
			askForFeedback()
		}
	}
	
	private func feedbackWeb(msg: MQTTMessage) {
		let host: String? = msg.payload.fogExtract()
		delegate?.train(webHost: host)
	}
    
    private func feedbackFault(msg: MQTTMessage) {
        self.fault.receive(msg.payload.fogExtract()) { value, asserted in
            delegate?.train(faults: value, asserted)
        }
    }
}
