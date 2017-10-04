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
	//func foggyLogo(calibration: FogRational<Int64>, _ asserted: Bool)
}

public class FoggyLogo: FogFeedbackModel {
	
	//Creating the broadcaster
	private var broadcaster: MQTTBroadcaster?
	
	//Responsible for dealing with light feedback
	private var lightsPower: FogFeedbackValue<Bool>
	
	public weak var delegate: FoggyLogoDelegate?
	
	public var mqtt: MQTTBridge! {
		didSet {
			broadcaster = mqtt.broadcast(to: self, queue: DispatchQueue.main, topics: [
				("lights/power/feedback", .atMostOnce, FoggyLogo.feedbackLightsPower)])
		}
	}
	
	public init() {
		self.lightsPower = FogFeedbackValue(false)
	}
	
	public var hasFeedback: Bool {
		return lightsPower.hasFeedback
	}
	
	public func reset() {
		lightsPower.reset()
	}
	
	public func assertValues() {
		delegate?.foggyLogo(lightsPower: lightsPower.value, true)
	}

	private func feedbackLightsPower(_ msg: MQTTMessage) {
		self.lightsPower.receive(msg.payload.fogExtract()) { value, asserted in
			delegate?.foggyLogo(lightsPower: value, asserted)
		}
	}
}
