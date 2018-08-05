//
//  MQTTMultiClientAppController.swift
//  SwiftyFog
//
//  Created by David Giovannini on 7/21/18.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

/*
	The MQTTMultiClientAppController manages the high level business logic of the
	application without managing the UI nor being the Cocoa AppDelegate.
*/

public protocol MQTTMultiClientAppControllerDelegate: class {
	func on(mqttClient: (MQTTBridge & MQTTControl), log: String)
	func on(mqttClient: (MQTTBridge & MQTTControl), connected: MQTTConnectedState)
}

public class MQTTClientSubscription: MQTTBridge, MQTTControl {
	private let client: (MQTTBridge & MQTTControl)
	private let creator: MQTTMultiClientAppController
	
	fileprivate init(client: (MQTTBridge & MQTTControl), creator: MQTTMultiClientAppController) {
		self.client = client
		self.creator = creator
	}
	
	deinit {
		creator.releaseClient(hostedOn: client.hostName)
	}
	
	public var hostName: String {
		return client.hostName
	}
	
	public var started: Bool {
		return client.started
	}
	
	public var connected: Bool {
		return client.connected
	}
	
	public func start() {
		return client.start()
	}
	
	public func stop() {
		return client.stop()
	}
	
	public func createBridge(subPath: String) -> MQTTBridge {
		return client.createBridge(subPath: subPath)
	}
	
	public func subscribe(topics: [(String, MQTTQoS)], acknowledged: SubscriptionAcknowledged?) -> MQTTSubscription {
		return client.subscribe(topics: topics, acknowledged: acknowledged)
	}
	
	public func register(topic: String, action: @escaping (MQTTMessage) -> ()) -> MQTTRegistration {
		return client.register(topic: topic, action: action)
	}
	
	public func publish(_ pubMsg: MQTTMessage, completion: ((Bool) -> ())?) {
		return client.publish(pubMsg, completion: completion)
	}
}

public class MQTTMultiClientAppController {
	// hn=`hostname`;cn=$(echo "$hn" | cut -f 1 -d '.');dns-sd -R ${cn} _mqtt._tcp local 1883&
	let bonjour = BonjourDiscovery(type: "mqtt", proto: "tcp")
	private var clients: [String : ((MQTTBridge & MQTTControl), Int, Bool)] = [:]
	private let network: FogNetworkReachability
	private let metrics: ()->MQTTMetrics?
	
	public weak var delegate: MQTTMultiClientAppControllerDelegate?
	
	public init(metrics: @escaping @autoclosure ()->MQTTMetrics?) {
		self.network = FogNetworkReachability()
		self.metrics = metrics
	
		bonjour.delegate = self
	}
	
	public func requestClient(hostedOn: String) -> (MQTTBridge & MQTTControl) {
		if let client = clients[hostedOn] {
			clients[hostedOn]?.1 += 1
			return client.0
		}
		let newClient = createClient(mqttHost: hostedOn)
		clients[hostedOn] = (newClient, 1, true)
		return MQTTClientSubscription(client: newClient, creator: self)
	}
	
	fileprivate func releaseClient(hostedOn: String) {
		if let client = clients[hostedOn], client.1 == 1 {
			client.0.stop()
			clients.removeValue(forKey: hostedOn)
		}
	}
	
	private func createClient(mqttHost: String) -> MQTTClient {
		var client = MQTTClientParams()
		client.detectServerDeath = 2
		let newClient = MQTTClient(
			client: client,
			host: MQTTHostParams(host: mqttHost, port: .standard),
			reconnect: MQTTReconnectParams(),
			metrics: metrics())

		newClient.delegate = self
		return newClient
	}
	
	public func goForeground() {
		// Network reachability can detect a disconnected state before the client
		network.start { [weak self] status in
			if status != .none {
				self?.bonjour.start()
				for client in (self?.clients)! {
					if client.value.2 {
						client.value.0.start()
					}
				}
			}
			else {
				self?.bonjour.stop()
				for client in (self?.clients)! {
					if client.value.2 {
						client.value.0.stop()
					}
				}
			}
		}
	}
	
	public func goBackground() {
		// Be a good iOS citizen and shutdown the connection and timers
		self.bonjour.stop()
		for host in clients.keys {
			let client = clients[host]!.0
			clients[host]!.2 = client.started
			client.stop()
		}
		network.stop()
	}
}

extension MQTTMultiClientAppController: MQTTClientDelegate {
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

extension MQTTMultiClientAppController: BonjourDiscoveryDelegate {
	public func bonjourDiscovery(_ bonjourDiscovery: BonjourDiscovery, didFailedAt: BonjourDiscoveryOperation, withErrorDict: [String : NSNumber]?) {
	}
	
	public func bonjourDiscovery(_ bonjourDiscovery: BonjourDiscovery, didFindService service: NetService, atHosts host: [String]) {
		print("Discovered \(service.name) \(host)")
	}
	
	public func bonjourDiscovery(_ bonjourDiscovery: BonjourDiscovery, didRemovedService service: NetService) {
		print("Undiscovered \(service.name)")
	}
	
	public func browserDidStart(_ bonjourDiscovery: BonjourDiscovery) {
	}
	
	public func browserDidStop(_ bonjourDiscovery: BonjourDiscovery) {
	}
	
	public func bonjourDiscovery(_ bonjourDiscovery: BonjourDiscovery, serviceDidUpdateTXT: NetService, TXT: Data) {
	}
}
