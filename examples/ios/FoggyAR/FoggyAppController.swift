//
//  ARAppController.swift
//  FoggyAR
//
//  Created by Tobias Schweiger on 10/4/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import UIKit
import SwiftyFog_iOS

protocol FoggyAppControllerDelegate: class {
	func on(connected: MQTTConnectedState)
}

class FoggyAppController {
	let mqtt: (MQTTBridge & MQTTControl)!
	let network: FogNetworkReachability
	
	private var fakeHeading : CGFloat = 0
	private var fakeHeadingTimer: DispatchSourceTimer?
	
	weak var delegate: FoggyAppControllerDelegate?
	
	init(_ trainName: String) {
		self.network = FogNetworkReachability()
		
		let metrics = MQTTMetrics()
		metrics.doPrintReceivePackets = true
		metrics.doPrintSendPackets = true
		metrics.debugOut = {print($0)}
		
		// Create the concrete MQTTClient to connect to a specific broker
		let mqtt = MQTTClient(
			host: MQTTHostParams(host: "thejoveexpress.local")
		)

		self.mqtt = mqtt
		mqtt.delegate = self

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
				let heading = FogRational(num: Int64(m.fakeHeading * 10.0), den: Int64(3600))
				var data  = Data(capacity: heading.fogSize)
				data.fogAppend(heading)
				m.mqtt.publish(MQTTMessage(topic: "thejoveexpress/accelerometer/feedback/heading", payload: data))
			}
		}
		self.fakeHeadingTimer = fakeHeadingTimer
		//fakeHeadingTimer.resume()
	}
}

extension FoggyAppController: MQTTClientDelegate {
	func mqtt(client: MQTTClient, connected: MQTTConnectedState) {
		DispatchQueue.main.async {
			self.delegate?.on(connected: connected)
		}
	}
	
	func mqtt(client: MQTTClient, unhandledMessage: MQTTMessage) {
	}
	
	func mqtt(client: MQTTClient, recreatedSubscriptions: [MQTTSubscription]) {
	}
}
