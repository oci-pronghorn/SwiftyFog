//
//  Thermometer.swift
//  SwiftyFog
//
//  Created by David Giovannini on 7/29/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation
import SwiftyFog_mac

public protocol ThermometerDelegate: class {
	func thermometer(temperature: FogRational<Int64>, _ asserted: Bool)
}

public class Thermometer: FogFeedbackModel {
	private var broadcaster: MQTTBroadcaster?
	private var temperature: FogFeedbackValue<FogRational<Int64>>
	
	public weak var delegate: ThermometerDelegate?
	
	public var mqtt: MQTTBridge! {
		didSet {
			broadcaster = mqtt.broadcast(to: self, queue: DispatchQueue.main, topics: [
				("temperature/feedback", .atMostOnce, Thermometer.feedbackTemperature)])
			//TODO: This isn't 100% how it's supposed to be, but right now we are just echoing
			//back. Next step is integrating feedback loop as seen in the Train.swift
			//Also fix the slider not responding to inputs
		}
	}
	
	public init() {
		self.temperature = FogFeedbackValue(FogRational())
	}
	
	public var hasFeedback: Bool {
		return temperature.hasFeedback
	}
	
	public func reset() {
		temperature.reset()
	}
	
	public func assertValues() {
		delegate?.thermometer(temperature: temperature.value, true)
	}
	
	public func control(temperature: FogRational<Int64>) {
		self.temperature.control(temperature) { value in
			var data  = Data(capacity: value.fogSize)
			data.fogAppend(value)
			//mqtt.publish(MQTTMessage(topic: "temperature/control", payload: data))
		}
	}
	
	private func feedbackTemperature(_ msg: MQTTMessage) {
		self.temperature.receive(msg.payload.fogExtract()) { value, asserted in
			delegate?.thermometer(temperature: value, asserted)
		}
	}
}

