//
//  MQTTClient.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/12/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

public struct MQTTReconnect {
    public var retryCount: Int = 3
    public var retryTimeInterval: TimeInterval = 1.0
    public var resuscitateTimeInterval: TimeInterval = 5.0
	
    public init() {
    }
}

public protocol MQTTClientDelegate: class {
	func mqttConnectAttempted(client: MQTTClient)
	func mqttConnected(client: MQTTClient)
	func mqttPinged(client: MQTTClient, status: MQTTPingStatus)
	func mqttSubscriptionChanged(client: MQTTClient, subscription: MQTTSubscription, status: MQTTSubscriptionStatus)
	func mqttDisconnected(client: MQTTClient, reason: MQTTConnectionDisconnect, error: Error?)
}

private class RetryConnection {
	private let spec: MQTTReconnect
	private let attemptConnect: ()->()
	
	var connected: Bool = false {
		didSet {
			if oldValue == true && connected == false {
				self.startConnect(attempt: 0)
			}
		}
	}
	
	init(spec: MQTTReconnect, attemptConnect: @escaping ()->()) {
		self.spec = spec
		self.attemptConnect = attemptConnect
	}
	
	func start() {
		startConnect(attempt: 0)
	}

	func startConnect(attempt: Int) {
		self.attemptConnect()
		if attempt == spec.retryCount {
			startResuscitation()
		}
		else {
			DispatchQueue.main.asyncAfter(deadline: .now() +  spec.retryTimeInterval) { [weak self] in
				self?.nextAttempt(attempt: attempt)
			}
		}
	}
	
	func nextAttempt(attempt: Int) {
		if connected == false {
			startConnect(attempt: attempt + 1)
		}
	}
	
	func startResuscitation() {
		if spec.resuscitateTimeInterval > 0.0 {
			DispatchQueue.main.asyncAfter(deadline: .now() +  spec.resuscitateTimeInterval) { [weak self] in
				self?.startConnect(attempt: 0)
			}
		}
	}
}

public final class MQTTClient {
	private let client: MQTTClientParams
	private let host: MQTTHostParams
	private let reconnect: MQTTReconnect
	
	private var publisher: MQTTPublisher
	private var subscriber: MQTTSubscriber
	private var distributer: MQTTDistributor
	private var connection: MQTTConnection?
	private var retry: RetryConnection?
	
    public weak var delegate: MQTTClientDelegate?
	
    public var debugPackageBytes : ((String)->())? {
		didSet {
			connection?.debugPackageBytes = debugPackageBytes
		}
    }
	
	public init(client: MQTTClientParams, host: MQTTHostParams = MQTTHostParams(), reconnect: MQTTReconnect = MQTTReconnect()) {
		self.client = client
		self.host = host
		self.reconnect = reconnect
		let idSource = MQTTMessageIdSource()
		self.publisher = MQTTPublisher(idSource: idSource)
		self.subscriber = MQTTSubscriber(idSource: idSource)
		self.distributer = MQTTDistributor(idSource: idSource)
		publisher.delegate = self
		subscriber.delegate = self
		distributer.delegate = self
	}
	
	public func start() {
		retry = RetryConnection(spec: reconnect, attemptConnect: { [weak self] in
			self?.makeConnection()
		})
		retry?.start()
	}
	
	private func makeConnection() {
		delegate?.mqttConnectAttempted(client: self)
		connection = MQTTConnection(hostParams: host, clientPrams: client)
		connection?.debugPackageBytes = debugPackageBytes
		connection?.delegate = self
	}
	
	public func stop() {
		retry = nil
		connection = nil
	}
	
	public func publish(pubMsg: MQTTPubMsg, retry: MQTTPublishRetry = MQTTPublishRetry(), completion: ((Bool)->())?) {
		publisher.publish(pubMsg: pubMsg, retry: retry, completion: completion)
	}
	
	public func subscribe(topics: [String: MQTTQoS], completion: ((Bool)->())?) -> MQTTSubscription {
		return subscriber.subscribe(topics: topics, completion: completion)
	}
	
	public func registerTopic(path: String, action: @escaping (MQTTMessage)->()) -> MQTTRegistration {
		return distributer.registerTopic(path: path, action: action)
	}
}

extension MQTTClient: MQTTConnectionDelegate {
	func mqttDisconnected(_ connection: MQTTConnection, reason: MQTTConnectionDisconnect, error: Error?) {
		publisher.disconnected(cleanSession: connection.cleanSession, final: reason == .shutdown)
		subscriber.disconnected(cleanSession: connection.cleanSession, final: reason == .shutdown)
		distributer.disconnected(cleanSession: connection.cleanSession, final: reason == .shutdown)
		// TODO: New language rules. I need to rethink delegate calls from deinit - as I should :-)
		if reason != .shutdown {
			self.connection = nil
		}
		delegate?.mqttDisconnected(client: self, reason: reason, error: error)
		retry?.connected = false
	}
	
	func mqttConnected(_ connection: MQTTConnection) {
		retry?.connected = true
		delegate?.mqttConnected(client: self)
		publisher.connected(cleanSession: connection.cleanSession)
		subscriber.connected(cleanSession: connection.cleanSession)
		distributer.connected(cleanSession: connection.cleanSession)
	}
	
	func mqttPinged(_ connection: MQTTConnection, status: MQTTPingStatus) {
		delegate?.mqttPinged(client: self, status: status)
	}
	
	func mqttReceived(_ connection: MQTTConnection, packet: MQTTPacket) {
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
	
	private func unhandledPacket(packet: MQTTPacket) {
		connection?.debugPackageBytes?("MQTT Unhandled: \(type(of:packet))")
	}
}

extension MQTTClient: MQTTPublisherDelegate, MQTTSubscriptionDelegate, MQTTDistributorDelegate {
	func send(packet: MQTTPacket) -> Bool {
		return connection?.send(packet: packet) ?? false
	}
	
	func subscriptionChanged(subscription: MQTTSubscription, status: MQTTSubscriptionStatus) {
		delegate?.mqttSubscriptionChanged(client: self, subscription: subscription, status: status)
	}
}
