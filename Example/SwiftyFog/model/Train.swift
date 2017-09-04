//
//  Train.swift
//  SwiftyFog_Example
//
//  Created by David Giovannini on 8/28/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import SwiftyFog

public protocol TrainDelegate: class {
	func trainDied()
}

public class Train: FogFeedbackModel {
	
	private var broadcaster: MQTTBroadcaster?
	
	public weak var delegate: TrainDelegate?
	
    public var mqtt: MQTTBridge! {
		didSet {
			broadcaster = mqtt.broadcast(to: self, queue: DispatchQueue.main, topics: [
				("died", .atLeastOnce, Train.feedbackDied)
			])
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
	
	private func feedbackDied(msg: MQTTMessage) {
		delegate?.trainDied()
	}
}
