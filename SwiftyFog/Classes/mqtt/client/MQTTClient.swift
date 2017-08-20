//
//  MQTTClient.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/12/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

public protocol MQTTClientDelegate: class {
	func mqttConnectAttempted(client: MQTTClient)
	func mqttConnected(client: MQTTClient)
	func mqttPinged(client: MQTTClient, status: MQTTPingStatus)
	func mqttSubscriptionChanged(client: MQTTClient, subscription: MQTTSubscriptionDetail, status: MQTTSubscriptionStatus)
	func mqttDisconnected(client: MQTTClient, reason: MQTTConnectionDisconnect, error: Error?)
	func mqttUnhandledMessage(message: MQTTMessage)
}

public final class MQTTClient {
	public let client: MQTTClientParams
	public let host: MQTTHostParams
	public let reconnect: MQTTReconnectParams
	
	private let idSource: MQTTMessageIdSource
    private let durability: MQTTPacketDurability
	private let publisher: MQTTPublisher
	private let subscriber: MQTTSubscriber
	private let distributer: MQTTDistributor
	private var connection: MQTTConnection?
	private var retry: MQTTRetryConnection?
	private var connectedCount: Int
	
    public weak var delegate: MQTTClientDelegate?
	
    public var debugOut : ((String)->())? {
		didSet {
			idSource.debugOut = debugOut
			connection?.debugOut = debugOut
		}
    }
	
	public init(client: MQTTClientParams = MQTTClientParams(), host: MQTTHostParams = MQTTHostParams(), reconnect: MQTTReconnectParams = MQTTReconnectParams()) {
		self.client = client
		self.host = host
		self.reconnect = reconnect
		connectedCount = 0
		idSource = MQTTMessageIdSource()
		self.durability = MQTTPacketDurability(idSource: idSource, resendInterval: client.resendPulseInterval)
		self.publisher = MQTTPublisher(durability: durability, qos2Mode: client.qos2Mode)
		self.subscriber = MQTTSubscriber(durability: durability)
		self.distributer = MQTTDistributor(durability: durability, qos2Mode: client.qos2Mode)
		
		durability.delegate = self
		publisher.delegate = self
		subscriber.delegate = self
		distributer.delegate = self
	}
	
	@discardableResult
	public func start() -> [MQTTSubscription] {
		if retry == nil {
			retry = MQTTRetryConnection(spec: reconnect, attemptConnect: { [weak self] in
				self?.makeConnection()
			})
			retry?.start()
		}
		// TODO on clean == false return recreated last known subscriptions
		return []
	}
	
	public func stop() {
		if retry != nil {
			retry = nil
			connection = nil
			// connection does not call delegate in deinit
			doDisconnect(reason: .manual, error: nil)
		}
	}
	
	private func makeConnection() {
		delegate?.mqttConnectAttempted(client: self)
		connection = MQTTConnection(hostParams: host, clientPrams: client)
		connection?.debugOut = debugOut
		connection?.delegate = self
	}
	
	private func unhandledPacket(packet: MQTTPacket) {
		debugOut?("* MQTT Unhandled: \(type(of:packet))")
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
	
	public func registerTopic(path: String, action: @escaping (MQTTMessage)->()) -> MQTTRegistration {
		let resolved = path.hasPrefix("$") ? String(path.dropFirst()) : path
		return distributer.registerTopic(path: resolved, action: action)
	}
}

extension MQTTClient: MQTTConnectionDelegate {
	func mqttDisconnected(_ connection: MQTTConnection, reason: MQTTConnectionDisconnect, error: Error?) {
		doDisconnect(reason: reason, error: error)
	}
	
	private func doDisconnect(reason: MQTTConnectionDisconnect, error: Error?) {
		var manual = false
		if case .manual = reason {
			manual = true
		}
		publisher.disconnected(cleanSession: client.cleanSession, manual: manual)
		subscriber.disconnected(cleanSession: client.cleanSession, manual: manual)
		distributer.disconnected(cleanSession: client.cleanSession, manual: manual)
		durability.disconnected(cleanSession: client.cleanSession, manual: manual)
		idSource.disconnected(cleanSession: client.cleanSession, manual: manual)
		self.connection = nil
		delegate?.mqttDisconnected(client: self, reason: reason, error: error)
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
	
	func mqttConnected(_ connection: MQTTConnection, present: Bool) {
		connectedCount += 1
		retry?.connected = true
		delegate?.mqttConnected(client: self)
		idSource.connected(cleanSession: client.cleanSession, present: present)
		durability.connected(cleanSession: client.cleanSession, present: present, initial: connectedCount == 1)
		publisher.connected(cleanSession: client.cleanSession, present: present, initial: connectedCount == 1)
		subscriber.connected(cleanSession: client.cleanSession, present: present, initial: connectedCount == 1)
		distributer.connected(cleanSession: client.cleanSession, present: present, initial: connectedCount == 1)
	}
	
	func mqttPinged(_ connection: MQTTConnection, status: MQTTPingStatus) {
		delegate?.mqttPinged(client: self, status: status)
	}
	
	func mqttReceived(_ connection: MQTTConnection, packet: MQTTPacket) {
		DispatchQueue.global().async { [weak self] in
			self?.dispatch(packet: packet)
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

	func send(packet: MQTTPacket) -> Bool {
		return connection?.send(packet: packet) ?? false
	}
	
	func unhandledMessage(message: MQTTMessage) {
		delegate?.mqttUnhandledMessage(message: message)
	}
	
	func subscriptionChanged(subscription: MQTTSubscriptionDetail, status: MQTTSubscriptionStatus) {
		delegate?.mqttSubscriptionChanged(client: self, subscription: subscription, status: status)
	}
}
