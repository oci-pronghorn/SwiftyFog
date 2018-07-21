//
//  MqttClientAppController.swift
//  TrainControl
//
//  Created by David Giovannini on 9/4/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation
#if os(iOS)
import SwiftyFog_iOS
#elseif os(watchOS)
import SwiftFog_watch
#endif

/*
	The MqttClientAppController manages the high level business logic of the
	application without managing the UI nor being the Cocoa AppDelegate.
*/

public protocol MqttClientAppControllerDelegate: class {
	func on(log: String)
	func on(connected: MQTTConnectedState)
}

public class MqttClientAppController {
	public private(set) var client: (MQTTBridge & MQTTControl)?
	private let network: FogNetworkReachability
	private let metrics: MQTTMetrics?
	private var wasStarted: Bool = true
	
	public weak var delegate: MqttClientAppControllerDelegate?
	
	public static func verboseMetrics() -> MQTTMetrics {
		let metrics = MQTTMetrics()
		metrics.doPrintSendPackets = true
		metrics.doPrintReceivePackets = true
		metrics.debugOut = {
		print("\(Date.nowInSeconds()) MQTT \($0)")}
		
		return metrics
	}
	
	public static func pedanticMetrics() -> MQTTMetrics {
		let metrics = MQTTMetrics()
		metrics.doPrintSendPackets = true
		metrics.doPrintReceivePackets = true
		metrics.doPrintWireData = true
		metrics.debugOut = {print("\(Date.nowInSeconds()) MQTT \($0)")}
		return metrics
	}
	
	public init(metrics: MQTTMetrics? = nil) {
		self.network = FogNetworkReachability()
		self.metrics = metrics
	}
	
	public var mqttHost: String = "" {
		didSet {
			if mqttHost != oldValue {
				var client = MQTTClientParams()
				client.detectServerDeath = 2
				let newClient = MQTTClient(
					client: client,
					host: MQTTHostParams(host: mqttHost, port: .standard),
					reconnect: MQTTReconnectParams(),
					metrics: metrics)
				
			// TODO: We currently have a crashing bug tearing down an existing controller. It is likely recent reference rule changes with deinits
				self.client.assign(newClient)
				newClient.delegate = self
			}
		}
	}
	
	public func goForeground() {
		// If want to be started, restore it
		if wasStarted {
			// Network reachability can detect a disconnected state before the client
			network.start { [weak self] status in
				if status != .none {
					self?.client?.start()
				}
				else {
					self?.client?.stop()
				}
			}
		}
	}
	
	public func goBackground() {
		// Be a good iOS citizen and shutdown the connection and timers
		wasStarted = client?.started ?? false
		client?.stop()
		network.stop()
	}
}

// The mqtt client will broadcast important events to the controller.
// The invoking thread is not known.
extension MqttClientAppController: MQTTClientDelegate {
	public func mqtt(client: MQTTClient, connected: MQTTConnectedState) {
		let log: String
		switch connected {
			case .started:
				log = "Started"
				break
			case .connected(_, _, _, let counter):
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
			case .disconnected(_, let reason, let error):
				log = "Disconnected \(reason) \(error?.localizedDescription ?? "")"
				break
		}
		DispatchQueue.main.async {
			self.delegate?.on(log: log)
			self.delegate?.on(connected: connected)
		}
	}
	
	public func mqtt(client: MQTTClient, unhandledMessage: MQTTMessage) {
		DispatchQueue.main.async {
			self.delegate?.on(log: "Unhandled \(unhandledMessage)")
		}
	}
	
	public func mqtt(client: MQTTClient, recreatedSubscriptions: [MQTTSubscription]) {
		DispatchQueue.main.async {
		}
	}
}

