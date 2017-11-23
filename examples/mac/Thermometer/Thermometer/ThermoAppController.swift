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
	
	weak var delegate: ThermoAppControllerDelegate?
	
	init() {
		// Setup metrics
		let metrics = MQTTMetrics()
		metrics.doPrintSendPackets = true
		metrics.doPrintReceivePackets = true
		metrics.debugOut = {print("\(Date.nowInSeconds()) MQTT \($0)")}
		
		// Create the concrete MQTTClient to connect to a specific broker
		let mqtt = MQTTClient(
			host: MQTTHostParams(host: "localhost"),
			metrics: metrics)
		
		self.mqtt = mqtt
		
		mqtt.delegate = self
	}
	
	public func start() {
		mqtt.start()
	}
	
	public func stop() {
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
		case .connected(_, _, _, let counter):
			log = "Connected \(counter)"
			break
		case .retry(_, let rescus, let attempt, _):
			log = "Connection Attempt \(rescus).\(attempt)"
			break
		case .retriesFailed(let counter, let rescus, _):
			log = "Connection Failed \(counter).\(rescus)"
			break
		case .pinged(let status):
			log = "Ping \(status)"
			break
		case .disconnected(_, let reason, let error):
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

