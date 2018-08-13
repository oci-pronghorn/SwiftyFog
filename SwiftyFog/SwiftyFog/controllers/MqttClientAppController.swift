//
//  MQTTClientAppController.swift
//  SwiftyFog
//
//  Created by David Giovannini on 9/4/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation // DispatchQueue

/*
	The MQTTClientAppController manages the high level business logic of the
	application without managing the UI nor being the Cocoa AppDelegate.
*/

public protocol MQTTClientAppControllerDelegate: class {
	func on(mqttClient: (MQTTBridge & MQTTControl), log: String)
	func on(mqttClient: (MQTTBridge & MQTTControl), connected: MQTTConnectedState)
}

public class MQTTClientAppController {
	private let clientParams: MQTTClientParams
	private let network: FogNetworkReachability
	private let metrics: MQTTMetrics?
	private var wasStarted: Bool = true
	public private(set) var client: (MQTTBridge & MQTTControl)?
	
	public weak var delegate: MQTTClientAppControllerDelegate?
	
	public init(client: MQTTClientParams = MQTTClientParams(), metrics: MQTTMetrics? = nil) {
		self.clientParams = client
		self.network = FogNetworkReachability()
		self.metrics = metrics
	}
	
	public var mqttHost: String = "" {
		didSet {
			if mqttHost != oldValue {
				let newClient = MQTTClient(
					client: clientParams,
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

extension MQTTClientAppController: MQTTClientDelegate {
	public func mqtt(client: MQTTClient, connected: MQTTConnectedState) {
		DispatchQueue.main.async {
			self.delegate?.on(mqttClient: client, log: connected.description)
			self.delegate?.on(mqttClient: client, connected: connected)
		}
	}
	
	public func mqtt(client: MQTTClient, unhandledMessage: MQTTMessage) {
		DispatchQueue.main.async {
			self.delegate?.on(mqttClient: client, log: "Unhandled \(unhandledMessage)")
		}
	}
	
	public func mqtt(client: MQTTClient, recreatedSubscriptions: [MQTTSubscription]) {
		DispatchQueue.main.async {
		}
	}
}
