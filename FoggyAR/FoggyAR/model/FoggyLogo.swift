//
//  FoggyLogo.swift
//  FoggyAR
//
//  Created by Tobias Schweiger on 10/4/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation
import SwiftyFog_iOS

public protocol FoggyLogoDelegate: class {
	func foggyLogo(lightsPower: Bool, _ asserted: Bool)
	func foggyLogo(accelerometerHeading: FogRational<Int64>, _ asserted: Bool)
}

public class FoggyLogo: FogFeedbackModel {
	
	//Creating the broadcaster
	private var broadcaster: MQTTBroadcaster?
	
	//Responsible for dealing with light feedback
	private var lightsPower: FogFeedbackValue<Bool>
	
	//The heading provided by the accelerometer
	private var accelerometerHeading: FogFeedbackValue<FogRational<Int64>>
	
	public weak var delegate: FoggyLogoDelegate?
	
	public var mqtt: MQTTBridge! {
		didSet {
			broadcaster = mqtt.broadcast(to: self, queue: DispatchQueue.main, topics: [
				("lights/power/feedback", .atMostOnce, FoggyLogo.feedbackLightsPower),
				("accelerometer/feedback/heading", .atMostOnce, FoggyLogo.feedbackAccelerometerHeading)
				])
		}
	}
	
	public init() {
		self.lightsPower = FogFeedbackValue(false)
		self.accelerometerHeading = FogFeedbackValue(FogRational(num: Int64(0), den: 360))
	}
	
	public func control(heading: FogRational<Int64>) {
		self.accelerometerHeading.control(heading) { value in
			var data  = Data(capacity: value.fogSize)
			data.fogAppend(value)
			mqtt.publish(MQTTMessage(topic: "accelerometer/feedback/heading", payload: data))
		}
	}
	
	public var hasFeedback: Bool {
		return lightsPower.hasFeedback && accelerometerHeading.hasFeedback
	}
	
	public func reset() {
		lightsPower.reset()
		accelerometerHeading.reset()
	}
	
	public func assertValues() {
		delegate?.foggyLogo(lightsPower: lightsPower.value, true)
		delegate?.foggyLogo(accelerometerHeading: accelerometerHeading.value, true)
	}

	private func feedbackLightsPower(_ msg: MQTTMessage) {
		self.lightsPower.receive(msg.payload.fogExtract()) { value, asserted in
			delegate?.foggyLogo(lightsPower: value, asserted)
		}
	}
	
	private func feedbackAccelerometerHeading(_ msg: MQTTMessage) {
		self.accelerometerHeading.receive(msg.payload.fogExtract()) { value, asserted in
			delegate?.foggyLogo(accelerometerHeading: value, asserted)
		}
	}
}
