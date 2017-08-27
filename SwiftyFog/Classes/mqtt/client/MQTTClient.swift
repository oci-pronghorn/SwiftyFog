//
//  MQTTClient.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/12/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

public enum MQTTConnectedState {
	case connected(Int)
	case discconnected(reason: MQTTConnectionDisconnect, error: Error?)
	case retry(Int, Int, MQTTReconnectParams) // escus counter, attempt counter
}

public protocol MQTTClientDelegate: class {
	func mqtt(client: MQTTClient, connected: MQTTConnectedState)
	func mqtt(client: MQTTClient, pinged: MQTTPingStatus)
	func mqtt(client: MQTTClient, subscription: MQTTSubscriptionDetail, changed: MQTTSubscriptionStatus)
	func mqtt(client: MQTTClient, unhandledMessage: MQTTMessage)
}

public final class MQTTClient {
	public let client: MQTTClientParams
	public let auth: MQTTAuthentication
	public let host: MQTTHostParams
	public let reconnect: MQTTReconnectParams
	
	private let queue: DispatchQueue
	private let socketQoS: DispatchQoS
	private let metrics: MQTTMetrics?

	private let idSource: MQTTMessageIdSource
    private let durability: MQTTPacketDurability
	private let publisher: MQTTPublisher
	private let subscriber: MQTTSubscriber
	private let distributer: MQTTDistributor
	
	private var connection: MQTTConnection?
	private var retry: MQTTRetryConnection?
	private var madeInitialConnection = false

    public weak var delegate: MQTTClientDelegate?
	
	public init(
			client: MQTTClientParams = MQTTClientParams(),
			host: MQTTHostParams = MQTTHostParams(),
			auth: MQTTAuthentication = MQTTAuthentication(),
			reconnect: MQTTReconnectParams = MQTTReconnectParams(),
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
		
		idSource = MQTTMessageIdSource(metrics: metrics)
		self.durability = MQTTPacketDurability(idSource: idSource, queuePubOnDisconnect: client.queuePubOnDisconnect, resendInterval: client.resendPulseInterval)
		self.publisher = MQTTPublisher(issuer: durability, queuePubOnDisconnect: client.queuePubOnDisconnect, qos2Mode: client.qos2Mode)
		self.subscriber = MQTTSubscriber(issuer: durability)
		self.distributer = MQTTDistributor(issuer: durability, qos2Mode: client.qos2Mode)
		
		self.madeInitialConnection = false
		
		durability.delegate = self
		publisher.delegate = self
		subscriber.delegate = self
		distributer.delegate = self
	}
	
	public var connected: Bool { return connection?.isFullConnected ?? false }
	
	@discardableResult
	public func start() -> [MQTTSubscription] {
		if retry == nil {
			retry = MQTTRetryConnection(spec: reconnect) { [weak self] r, a in
				self?.makeConnection(r, a)
			}
			retry?.start()
		}
		return []
	}
	
	public func stop() {
		if retry != nil {
			retry = nil
			connection = nil
			// connection does not call delegate in deinit
			doDisconnect(reason: .stopped, error: nil)
		}
	}
	
	private func makeConnection(_ rescus: Int, _ attempt : Int) {
		delegate?.mqtt(client: self, connected: .retry(rescus, attempt, self.reconnect))
		connection = MQTTConnection(
			hostParams: host,
			clientPrams: client,
			authPrams: auth,
			socketQoS: socketQoS,
			metrics: metrics)
		if let connection = connection {
			connection.start(delegate: self)
		}
		else {
			doDisconnect(reason: .socket, error: nil)
		}
	}
	
	private func unhandledPacket(packet: MQTTPacket) {
		if let metrics = metrics {
			metrics.unhandledPacket()
			metrics.debug("Unhandled: \(type(of:packet))")
		}
	}
}

extension MQTTClient: MQTTBridge {
	public func createBridge(subPath: String) -> MQTTBridge {
		return MQTTTopicScope(base: self, fullPath: subPath)
	}

	public func publish(_ pubMsg: MQTTPubMsg, completion: ((Bool)->())?) {
		let path = String(pubMsg.topic)
		let resolved = path.hasPrefix("$") ? String(path.dropFirst()) : path
		let newMessage = MQTTPubMsg(topic: resolved, payload: pubMsg.payload, retain: pubMsg.retain, qos: pubMsg.qos)
		publisher.publish(pubMsg: newMessage, completion: completion)
	}
	
	public func subscribe(topics: [(String, MQTTQoS)], completion: ((Bool)->())?) -> MQTTSubscription {
		let resolved = topics.map { (
			$0.0.hasPrefix("$") ? String($0.0.dropFirst()) : $0.0,
			$0.1
		)}
		return subscriber.subscribe(topics: resolved, completion: completion)
	}
	
	public func register(topic: String, action: @escaping (MQTTMessage)->()) -> MQTTRegistration {
		let resolved = topic.hasPrefix("$") ? String(topic.dropFirst()) : topic
		return distributer.registerTopic(path: resolved, action: action)
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
		publisher.disconnected(cleanSession: client.cleanSession, stopped: stopped)
		subscriber.disconnected(cleanSession: client.cleanSession, stopped: stopped)
		distributer.disconnected(cleanSession: client.cleanSession, stopped: stopped)
		durability.disconnected(cleanSession: client.cleanSession, stopped: stopped)
		idSource.disconnected(cleanSession: client.cleanSession, stopped: stopped)
		self.connection = nil
		delegate?.mqtt(client: self, connected: .discconnected(reason: reason, error: error))
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
		delegate?.mqtt(client: self, connected: .connected(0))
		idSource.connected(cleanSession: client.cleanSession, present: connectedAsPresent, initial: wasInitialConnection)
		durability.connected(cleanSession: client.cleanSession, present: connectedAsPresent, initial: wasInitialConnection)
		publisher.connected(cleanSession: client.cleanSession, present: connectedAsPresent, initial: wasInitialConnection)
		subscriber.connected(cleanSession: client.cleanSession, present: connectedAsPresent, initial: wasInitialConnection)
		distributer.connected(cleanSession: client.cleanSession, present: connectedAsPresent, initial: wasInitialConnection)
	}
	
	func mqtt(connection: MQTTConnection, pinged: MQTTPingStatus) {
		delegate?.mqtt(client: self, pinged: pinged)
	}
	
	func mqtt(connection: MQTTConnection, received: MQTTPacket) {
		queue.async { [weak self] in
			self?.dispatch(packet: received)
		}
	}
	
	private func dispatch(packet: MQTTPacket) {
		var handled = distributer.receive(packet: packet)
		if handled == false {
			handled = publisher.receive(packet: packet)
			if handled == false {
				handled = subscriber.receive(packet: packet)
				if handled == false {
					unhandledPacket(packet: packet)
				}
			}
		}
	}
}

extension MQTTClient:
		MQTTPublisherDelegate,
		MQTTSubscriptionDelegate,
		MQTTDistributorDelegate,
		MQTTPacketDurabilityDelegate {
	func mqtt(send: MQTTPacket, completion: @escaping (Bool)->()) {
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
	
	func mqtt(unhandledMessage: MQTTMessage) {
		delegate?.mqtt(client: self, unhandledMessage: unhandledMessage)
	}
	
	func mqtt(subscription: MQTTSubscriptionDetail, changed: MQTTSubscriptionStatus) {
		delegate?.mqtt(client: self, subscription: subscription, changed: changed)
	}
}
