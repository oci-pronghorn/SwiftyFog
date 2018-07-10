//
//  FoggyLogo.swift
//  FoggyAR
//
//  Created by Tobias Schweiger on 10/4/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation
import SwiftyFog_iOS

public typealias TrainRational = FogRational<Int32>

public protocol FoggyLogoDelegate: class {
	func foggyLogo(lightsPower: Bool)
	func foggyLogo(alive: Bool)
	func foggyLogo(accelerometerHeading: TrainRational)
}

public class FoggyLogo {
	//Creating the broadcaster
	private var broadcaster: MQTTBroadcaster?
	
	public weak var delegate: FoggyLogoDelegate?
	
	public var mqtt: MQTTBridge! {
		didSet {
			broadcaster = mqtt.broadcast(to: self, queue: DispatchQueue.main, topics: [
				("lights/power/feedback", .atMostOnce, FoggyLogo.feedbackLightsPower),
				("location/heading/feedback", .atMostOnce, FoggyLogo.feedbackAccelerometerHeading),
				("lifecycle/feedback", .atLeastOnce, FoggyLogo.feedbackLifecycle)
			])
		}
	}

	private func feedbackLightsPower(_ msg: MQTTMessage) {
		let value: Bool = msg.payload.fogExtract()
		delegate?.foggyLogo(lightsPower: value)
	}
	
	private func feedbackAccelerometerHeading(_ msg: MQTTMessage) {
		let value: TrainRational = msg.payload.fogExtract()!
		delegate?.foggyLogo(accelerometerHeading: value)
	}
	
	private func feedbackLifecycle(msg: MQTTMessage) {
		let alive: Bool = msg.payload.fogExtract()
		delegate?.foggyLogo(alive: alive)
		if alive {
			askForFeedback()
		}
	}
	private func askForFeedback() {
		mqtt.publish(MQTTMessage(topic: "feedback", qos: .atLeastOnce))
	}
}
