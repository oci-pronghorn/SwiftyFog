//
//  MQTTConnectionManager.swift
//  SwiftyFog_iOS
//
//  Created by David Giovannini on 11/23/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

public protocol MQTTConnectionManagerDelegate: class {
	func mqtt(connected: MQTTConnectedState)
	func mqtt(received: MQTTPacket)
}

public final class MQTTConnectionManager {
    private let factory: MQTTPacketFactory
	private let metrics: MQTTMetrics?

	private let client: MQTTClientParams
	private let host: MQTTHostParams
	private let auth: MQTTAuthentication
	private let reconnect: MQTTReconnectParams
	private let socketQoS: DispatchQoS

	private var connection: MQTTConnection?
	private var retry: MQTTRetryConnection?
	
	private var connectionCounter = 0
	private var madeInitialConnection = false
	
	public var hostName: String {
		return self.host.host
	}
	
    public weak var delegate: MQTTConnectionManagerDelegate?

	public init(
			factory: MQTTPacketFactory,
			client: MQTTClientParams = MQTTClientParams(),
			host: MQTTHostParams = MQTTHostParams(),
			auth: MQTTAuthentication = MQTTAuthentication(),
			reconnect: MQTTReconnectParams = MQTTReconnectParams(),
			socketQoS: DispatchQoS = .userInitiated,
			metrics: MQTTMetrics? = nil) {
		self.factory = factory
		self.metrics = metrics
		self.client = client
		self.host = host
		self.auth = auth
		self.reconnect = reconnect
		self.socketQoS = socketQoS
	}
	
    public func send(packet: MQTTPacket, completion: @escaping (Bool)->()) {
		if let connection = connection, connected {
			let success = connection.send(packet: packet)
			completion(success)
		}
		else {
			completion(false)
		}
    }

	private func makeConnection(_ rescus: Int, _ attempt : Int?) {
		if let attempt = attempt {
			delegate?.mqtt(connected: .retry(connectionCounter, rescus, attempt, self.reconnect))
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
			delegate?.mqtt(connected: .retriesFailed(connectionCounter, rescus, self.reconnect));
		}
	}
}

extension MQTTConnectionManager: MQTTControl {
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
			delegate?.mqtt(connected: .started)
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

extension MQTTConnectionManager: MQTTConnectionDelegate {
	func mqtt(connection: MQTTConnection, disconnected: MQTTConnectionDisconnect, error: Error?) {
		doDisconnect(reason: disconnected, error: error)
	}

	private func doDisconnect(reason: MQTTConnectionDisconnect, error: Error?) {
		self.connection = nil
		delegate?.mqtt(connected: .disconnected(cleanSession: client.cleanSession, reason: reason, error: error))
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
		delegate?.mqtt(connected: .connected(cleanSession: client.cleanSession, connectedAsPresent: connectedAsPresent, isInitial: wasInitialConnection, connectionCounter: connectionCounter))
	}

	func mqtt(connection: MQTTConnection, pinged status: MQTTPingStatus) {
		delegate?.mqtt(connected: .pinged(status))
	}

	func mqtt(connection: MQTTConnection, received: MQTTPacket) {
		delegate?.mqtt(received: received)
	}
}
