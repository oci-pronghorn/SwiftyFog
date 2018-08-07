//
//  MQTTClient.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/12/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation // DispatchQueue

public protocol MQTTClientDelegate: class {
	func mqtt(client: MQTTClient, connected: MQTTConnectedState)
	func mqtt(client: MQTTClient, unhandledMessage: MQTTMessage)
	func mqtt(client: MQTTClient, recreatedSubscriptions: [MQTTSubscription])
}

public final class MQTTClient {
	private let connect: MQTTConnectionManager
    private let router: MQTTRouter
	private let queue: DispatchQueue

    public weak var delegate: MQTTClientDelegate?
	
	public init(
			client: MQTTClientParams = MQTTClientParams(),
			host: MQTTHostParams = MQTTHostParams(),
			auth: MQTTAuthentication = MQTTAuthentication(),
			reconnect: MQTTReconnectParams = MQTTReconnectParams(),
			routing: MQTTRoutingParams = MQTTRoutingParams(),
			queue: DispatchQueue = DispatchQueue.global(),
			socketQoS: DispatchQoS = .userInitiated,
			metrics: MQTTMetrics? = nil) {
		self.queue = queue
		self.connect = MQTTConnectionManager(
			factory: MQTTPacketFactory(metrics: metrics),
			client: client,
			host: host,
			auth: auth,
			reconnect: reconnect,
			socketQoS: socketQoS,
			metrics: metrics);
		self.router = MQTTRouter(
			host: host.host,
			metrics: metrics,
			routing: routing)
		
		router.delegate = self
		connect.delegate = self
	}
}

extension MQTTClient: MQTTControl {
	public var hostName: String {
		return self.connect.hostName
	}
	
	public var started: Bool {
		return self.connect.started
	}
	
	public var connected: Bool {
		get {
			return self.connect.connected
		}
		set {
			self.connect.connected = newValue
		}
	}

	public func start() {
		return self.connect.start()
	}

	public func stop() {
		return self.connect.stop()
	}
}

extension MQTTClient: MQTTBridge {
	public func createBridge(subPath: String) -> MQTTBridge {
		return router.createBridge(subPath: subPath)
	}

	public func publish(_ pubMsg: MQTTMessage, completion: ((Bool)->())?) {
		router.publish(pubMsg, completion: completion)
	}
	
	public func subscribe(topics: [(String, MQTTQoS)], acknowledged: SubscriptionAcknowledged?) -> MQTTSubscription {
		return router.subscribe(topics: topics, acknowledged: acknowledged)
	}
	
	public func register(topic: String, action: @escaping (MQTTMessage)->()) -> MQTTRegistration {
		return router.register(topic: topic, action: action)
	}
}

extension MQTTClient: MQTTConnectionManagerDelegate {
	public func mqtt(connected: MQTTConnectedState) {
		switch connected {
			case .started:
				break
			case .connected(let cleanSession, let connectedAsPresent, let wasInitialConnection, _):
				let recreatedSubscriptions = router.connected(cleanSession: cleanSession, present: connectedAsPresent, initial: wasInitialConnection)
				delegate?.mqtt(client: self, recreatedSubscriptions: recreatedSubscriptions)
			case .pinged:
				break
			case .disconnected(let cleanSession, let reason, let error):
				var stopped = false
				if case .stopped = reason {
					stopped = true
				}
				router.disconnected(cleanSession: cleanSession, stopped: stopped, reason: reason, error: error)
			case .retry:
				break
			case .retriesFailed:
				break
		}
		delegate?.mqtt(client: self, connected: connected)
	}
	
	public func mqtt(received: MQTTPacket) {
		queue.async { [weak self] in
			self?.router.dispatch(packet: received)
		}
	}
}

extension MQTTClient: MQTTRouterDelegate {
	public func mqtt(send: MQTTPacket, completion: @escaping (Bool)->()) {
		queue.async { [weak self] in
			self?.connect.send(packet: send, completion: completion)
		}
	}
	
	public func mqtt(unhandledMessage: MQTTMessage) {
		delegate?.mqtt(client: self, unhandledMessage: unhandledMessage)
	}
}
