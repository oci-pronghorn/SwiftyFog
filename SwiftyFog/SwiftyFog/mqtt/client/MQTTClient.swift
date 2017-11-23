//
//  MQTTClient.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/12/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

public protocol MQTTClientDelegate: class {
	func mqtt(client: MQTTClient, connected: MQTTConnectedState)
	func mqtt(client: MQTTClient, unhandledMessage: MQTTMessage)
	func mqtt(client: MQTTClient, recreatedSubscriptions: [MQTTSubscription])
}

public final class MQTTClient {
	public let client: MQTTClientParams
	public let host: MQTTHostParams
	public let auth: MQTTAuthentication
	public let reconnect: MQTTReconnectParams
	
	private let metrics: MQTTMetrics?
    private let router: MQTTRouter
    private let factory: MQTTPacketFactory
	
	// TODO create class to encapsulate this functionality
	private var connection: MQTTConnection?
	private var retry: MQTTRetryConnection?
	private var madeInitialConnection = false
	private var connectionCounter = 0
	private let queue: DispatchQueue
	private let socketQoS: DispatchQoS

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
		self.client = client
		self.host = host
		self.auth = auth
		self.reconnect = reconnect
		self.queue = queue
		self.socketQoS = socketQoS
		self.metrics = metrics
		self.router = MQTTRouter(metrics: metrics, routing: routing)
		self.factory = MQTTPacketFactory(metrics: metrics)
		
		self.madeInitialConnection = false
		
		router.delegate = self
	}
	
	private func makeConnection(_ rescus: Int, _ attempt : Int?) {
		if let attempt = attempt {
			delegate?.mqtt(client: self, connected: .retry(connectionCounter, rescus, attempt, self.reconnect))
			let connection = MQTTConnection(
				factory: factory,
				hostParams: host,
				clientPrams: client,
				authPrams: auth,
				socketQoS: socketQoS,
				metrics: metrics)
			self.connection = connection
			connection.start(delegate: self)
		}
		else {
			delegate?.mqtt(client: self, connected: .retriesFailed(connectionCounter, rescus, self.reconnect));
		}
	}
	
	private func unhandledPacket(packet: MQTTPacket) {
		if let metrics = metrics {
			metrics.unhandledPacket()
			if metrics.printUnhandledPackets {
				metrics.debug("Unhandled: \(packet)")
			}
		}
	}
}

extension MQTTClient: MQTTControl {
	public var started: Bool {
		return retry != nil
	}
	
	public var connected: Bool {
		get {
			return connection?.isFullConnected ?? false
		}
		set {
			newValue ? start(): stop()
		}
	}

	public func start() {
		if retry == nil {
			retry = MQTTRetryConnection(spec: reconnect) { [weak self] r, a in
				self?.makeConnection(r, a)
			}
			delegate?.mqtt(client: self, connected: .started)
			retry?.start()
		}
	}

	public func stop() {
		if retry != nil {
			retry = nil
			connection = nil
			// connection does not call delegate in deinit
			doDisconnect(reason: .stopped, error: nil)
		}
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

extension MQTTClient: MQTTConnectionDelegate {
	func mqtt(connection: MQTTConnection, disconnected: MQTTConnectionDisconnect, error: Error?) {
		doDisconnect(reason: disconnected, error: error)
	}
	
	private func doDisconnect(reason: MQTTConnectionDisconnect, error: Error?) {
		var stopped = false
		if case .stopped = reason {
			stopped = true
		}
		router.disconnected(cleanSession: client.cleanSession, stopped: stopped, reason: reason, error: error)
		self.connection = nil
		delegate?.mqtt(client: self, connected: .disconnected(reason: reason, error: error))
		if case let .handshake(ack) = reason {
			if ack.retries {
				retry?.connected = false
			}
			else {
				retry = nil
			}
		}
		else {
			retry?.connected = false
		}
	}
	
	func mqtt(connection: MQTTConnection, connectedAsPresent: Bool) {
		metrics?.madeConnection()
		let wasInitialConnection = madeInitialConnection == false
		madeInitialConnection = true

		retry?.connected = true
		connectionCounter += 1
		delegate?.mqtt(client: self, connected: .connected(connectionCounter))
		let recreatedSubscriptions = router.connected(cleanSession: client.cleanSession, present: connectedAsPresent, initial: wasInitialConnection)
		delegate?.mqtt(client: self, recreatedSubscriptions: recreatedSubscriptions)
	}
	
	func mqtt(connection: MQTTConnection, pinged status: MQTTPingStatus) {
		delegate?.mqtt(client: self, connected: .pinged(status))
	}
	
	func mqtt(connection: MQTTConnection, received: MQTTPacket) {
		queue.async { [weak self] in
			self?.router.dispatch(packet: received)
		}
	}
}

extension MQTTClient: MQTTRouterDelegate {
	public func mqtt(send: MQTTPacket, completion: @escaping (Bool)->()) {
		if let connection = connection, connected {
			queue.async {
				let success = connection.send(packet: send)
				completion(success)
			}
		}
		else {
			completion(false)
		}
	}
	
	public func mqtt(unhandledMessage: MQTTMessage) {
		delegate?.mqtt(client: self, unhandledMessage: unhandledMessage)
	}
}
