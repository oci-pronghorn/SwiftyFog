//
//  TrainAppController.swift
//  TrainControl
//
//  Created by David Giovannini on 9/4/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation
import SwiftyFog_iOS

/*
	The TrainAppController manages the high level business logic of the
	application without managing the UI nor being the Cocoa AppDelegate.
*/

protocol TrainAppControllerDelegate: class {
	func on(log: String)
	func on(connected: MQTTConnectedState)
}

class TrainAppController {
	let mqtt: (MQTTBridge & MQTTControl)!
	let network: NetworkReachability
	let metrics: MQTTMetrics?
	var wasStarted: Bool = true
	
	weak var delegate: TrainAppControllerDelegate?
	
	init(_ trainName: String) {
		self.network = NetworkReachability()
	
		// Setup metrics
		self.metrics = MQTTMetrics()
		self.metrics?.doPrintSendPackets = true
		self.metrics?.doPrintReceivePackets = true
		//metrics?.doPrintWireData = true
		self.metrics?.debugOut = {print("\(Date.nowInSeconds()) MQTT \($0)")}

		// Create the concrete MQTTClient to connect to a specific broker
		var client = MQTTClientParams()
		client.detectServerDeath = 2
		let mqtt = MQTTClient(
			client: client,
			host: MQTTHostParams(host: trainName + ".local", port: .standard),
			auth: MQTTAuthentication(username: "dsjove", password: "password"),
			reconnect: MQTTReconnectParams(),
			metrics: metrics)
		
		self.mqtt = mqtt
		mqtt.delegate = self
	}
	
	public func goForeground() {
		// If want to be started, restore it
		if wasStarted {
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
	}
	
	public func goBackground() {
		// Be a good iOS citizen and shutdown the connection and timers
		wasStarted = mqtt.started
		mqtt.stop()
		network.stop()
	}
}

// The mqtt client will broadcast important events to the controller.
// The invoking thread is not known.
extension TrainAppController: MQTTClientDelegate {
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
				log = "Ping \(status)"
				break
			case .retry(_, let rescus, let attempt, _):
				log = "Connection Attempt \(rescus).\(attempt)"
				break
			case .retriesFailed(let counter, let rescus, _):
				log = "Connection Failed \(counter).\(rescus)"
				break
			case .disconnected(let reason, let error):
				log = "Disconnected \(reason) \(error?.localizedDescription ?? "")"
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
		}
	}
}

