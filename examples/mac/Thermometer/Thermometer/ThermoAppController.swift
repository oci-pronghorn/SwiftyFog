//
//  ThermoAppController.swift
//  Thermometer
//
//  Created by Tobias Schweiger on 9/27/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation
import SwiftyFog_mac

protocol ThermoAppControllerDelegate: class {
	func on(log: String)
	func on(connected: MQTTConnectedState)
}

class ThermoAppController {
	let mqtt: (MQTTBridge & MQTTControl)!
	let metrics: MQTTMetrics?
	
	weak var delegate: ThermoAppControllerDelegate?
	
	init() {
		// Setup metrics
		metrics = MQTTMetrics()
		metrics?.doPrintSendPackets = true
		metrics?.doPrintReceivePackets = true
		metrics?.doPrintWireData = true
		metrics?.debugOut = {print("\(Date.nowInSeconds()) MQTT \($0)")}
		
		// Create the concrete MQTTClient to connect to a specific broker
		let client = MQTTClientParams()
		
		let mqtt = MQTTClient(metrics: metrics)
			//client: client,
			//host: MQTTHostParams(host: "localhost"),
			//auth: MQTTAuthentication(username: "tobischw", password: "password"),
			//reconnect: MQTTReconnectParams(),
			//metrics: metrics)
		
		self.mqtt = mqtt
		
		mqtt.delegate = self
		
	}
	
	public func goForeground() {
			mqtt.start()
	}
	
	public func goBackground() {
		// Be a good MacOS citizen and shutdown the connection and timers
		mqtt.stop()
	}
}

// The client will broadcast important events to the application
// can react appropriately. The invoking thread is not known.
extension ThermoAppController: MQTTClientDelegate {
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
			self.delegate?.on(log: "Received (unhandled): \(unhandledMessage)")
		}
	}
	
	func mqtt(client: MQTTClient, recreatedSubscriptions: [MQTTSubscription]) {
		DispatchQueue.main.async {
		}
	}
}

