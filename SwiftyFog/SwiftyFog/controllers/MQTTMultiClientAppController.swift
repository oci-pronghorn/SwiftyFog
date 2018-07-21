//
//  MQTTMultiClientAppController.swift
//  SwiftyFog
//
//  Created by David Giovannini on 9/4/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

/*
	The MQTTMultiClientAppController manages the high level business logic of the
	application without managing the UI nor being the Cocoa AppDelegate.
*/

public protocol MQTTMultiClientAppControllerDelegate: class {
	func on(log: String)
	func on(connected: MQTTConnectedState)
}

public class MQTTMultiClientAppController {
	public private(set) var client: (MQTTBridge & MQTTControl)?
	private let network: FogNetworkReachability
	private let metrics: MQTTMetrics?
	private var wasStarted: Bool = true
	
	public weak var delegate: MQTTMultiClientAppControllerDelegate?
	
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
				
				self.client.assign(newClient)
				newClient.delegate = self
				
				if wasStarted {
					self.client?.start()
				}
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
extension MQTTMultiClientAppController: MQTTClientDelegate {
	public func mqtt(client: MQTTClient, connected: MQTTConnectedState) {
		DispatchQueue.main.async {
			self.delegate?.on(log: connected.description)
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

