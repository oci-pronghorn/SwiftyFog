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
	func foggyLogo(lightsPower: Bool)
	func foggyLogo(accelerometerHeading: FogRational<Int64>)
}

public class FoggyLogo {
	//Creating the broadcaster
	private var broadcaster: MQTTBroadcaster?
	
	//Responsible for dealing with light feedback
	private var lightsPower: Bool
	
	//The heading provided by the accelerometer
	private var accelerometerHeading: FogRational<Int64> 
	
	public weak var delegate: FoggyLogoDelegate?
	
	public var mqtt: MQTTBridge! {
		didSet {
			broadcaster = mqtt.broadcast(to: self, queue: DispatchQueue.main, topics: [
				("lights/power/feedback", .atMostOnce, FoggyLogo.feedbackLightsPower),
				("location/heading/feedback", .atMostOnce, FoggyLogo.feedbackAccelerometerHeading)
				])
		}
	}
	
	public init() {
		self.lightsPower = false
		self.accelerometerHeading = FogRational(num: Int64(0), den: 360)
	}

	private func feedbackLightsPower(_ msg: MQTTMessage) {
		let value: Bool = msg.payload.fogExtract()
		delegate?.foggyLogo(lightsPower: value)
	}
	
	private func feedbackAccelerometerHeading(_ msg: MQTTMessage) {
		let value: FogRational<Int64> = msg.payload.fogExtract()!
		delegate?.foggyLogo(accelerometerHeading: value)
	}

}
