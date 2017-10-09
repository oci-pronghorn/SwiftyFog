//
//  ARAppController.swift
//  FoggyAR
//
//  Created by Tobias Schweiger on 10/4/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import UIKit
import SwiftyFog_iOS

class ARAppController {
	let mqtt: (MQTTBridge & MQTTControl)!
	let network: NetworkReachability
	
	// TODO: fakeHeadingTimer is for testing and demo-purposes, don't actually use it prod
	private var fakeHeading : CGFloat = 0
	private var fakeHeadingTimer: DispatchSourceTimer?
	
	init(_ trainName: String) {
		self.network = NetworkReachability()
		
		// Create the concrete MQTTClient to connect to a specific broker
		let mqtt = MQTTClient(
			host: MQTTHostParams(host: "thejoveexpress.local")
		)

		self.mqtt = mqtt
		
		createFakeTimer();
	}
	
	public func goForeground() {
			// Network reachability can detect a disconnected state before the client
			network.start { [weak self] status in
				if status != .none {
					self?.mqtt.start()
				}
				else {
					self?.mqtt.stop()
				}
			}
	}
	
	public func goBackground() {
		// Be a good iOS citizen and shutdown the connection and timers
		mqtt.stop()
		network.stop()
	}
	
	func createFakeTimer() {
		// Fake timer
		let fakeHeadingTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
		
		fakeHeading = 3.0
		let fakeIncrement: CGFloat = 13
		
		let interval = 1
		let leeway = 1
		fakeHeadingTimer.schedule(deadline: .now() + .seconds(interval), repeating: .seconds(interval), leeway: .seconds(leeway))
		fakeHeadingTimer.setEventHandler { [weak self] in
			if let m = self {
				m.fakeHeading += fakeIncrement;
				if m.fakeHeading < 0 {
					m.fakeHeading += 360
				}
				else if m.fakeHeading >= 360 {
					m.fakeHeading -= 360
				}
				let heading = FogRational(num: Int64(m.fakeHeading), den: Int64(360))
				var data  = Data(capacity: heading.fogSize)
				data.fogAppend(heading)
				m.mqtt.publish(MQTTMessage(topic: "thejoveexpress/accelerometer/feedback/heading", payload: data))
			}
		}
		self.fakeHeadingTimer = fakeHeadingTimer
		fakeHeadingTimer.resume()
	}
}
