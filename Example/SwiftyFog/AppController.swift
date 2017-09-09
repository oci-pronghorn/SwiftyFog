//
//  AppController.swift
//  SwiftyFog_Example
//
//  Created by David Giovannini on 9/4/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation
import SwiftyFog

protocol AppControllerDelegate: class {
	func on(log: String)
	func on(connected: MQTTConnectedState)
}

class AppController {
	var mqtt: (MQTTBridge & MQTTControl)!
	var metrics: MQTTMetrics?
	var wasStarted: Bool = false
	
	weak var delegate: AppControllerDelegate?
	
	init(_ trainName: String) {
		// Setup metrics
		metrics = MQTTMetrics(prefix: {"\(Date.nowInSeconds()) MQTT "})
		metrics?.doPrintSendPackets = true
		metrics?.doPrintReceivePackets = true
		//metrics?.doPrintWireData = true
		metrics?.debugOut = {print($0)}

		// Create the concrete MQTTClient to connect to a specific broker
		let mqtt = MQTTClient(
			host: MQTTHostParams(host: trainName + ".local", port: .standard),
			auth: MQTTAuthentication(username: "dsjove", password: "password"),
			reconnect: MQTTReconnectParams(),
			metrics: metrics)
		mqtt.delegate = self
		
		self.mqtt = mqtt
	}
	
	public func goForeground() {
		// If want to be started, restore it
		if wasStarted {
			mqtt.start()
		}
	}
	
	public func goBackground() {
		// Be a good iOS citizen and shutdown the connection and timers
		wasStarted = mqtt.started
		mqtt.stop()
	}
}

// The client will broadcast important events to the application
// can react appropriately. The invoking thread is not known.
extension AppController: MQTTClientDelegate {
	func mqtt(client: MQTTClient, connected: MQTTConnectedState) {
		let log: String
		switch connected {
			case .started:
				log = "Started"
				break
			case .connected(let counter):
				log = "Connected \(counter)"
				break
			case .pinged(let status):
				log = "Pinged \(status)"
				break
			case .retry(_, let rescus, let attempt, _):
				log = "Connection Attempt \(rescus).\(attempt)"
				break
			case .retriesFailed(let counter, let rescus, _):
				log = "Connection Failed \(counter).\(rescus)"
				break
			case .discconnected(let reason, let error):
				log = "Discconnected \(reason) \(error?.localizedDescription ?? "")"
				break
		}
		DispatchQueue.main.async {
			self.delegate?.on(log: log)
			self.delegate?.on(connected: connected)
		}
	}
	
	func mqtt(client: MQTTClient, unhandledMessage: MQTTMessage) {
		DispatchQueue.main.async {
			self.delegate?.on(log: "Unhandled \(unhandledMessage)")
		}
	}
	
	func mqtt(client: MQTTClient, recreatedSubscriptions: [MQTTSubscription]) {
		DispatchQueue.main.async {
			// TODO if not clean and session present then likely we will have
			// recreated RAII subscription objects that unless dealt with will
			// unsubscribe
		}
	}
}

