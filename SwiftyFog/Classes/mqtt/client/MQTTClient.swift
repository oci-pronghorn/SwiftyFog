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
    private let resendTimer: DispatchSourceTimer
	private let publisher: MQTTPublisher
	private let subscriber: MQTTSubscriber
	private let distributer: MQTTDistributor
	private var connection: MQTTConnection?
	private var retry: MQTTRetryConnection?
	
    public weak var delegate: MQTTClientDelegate?
	
    public var debugOut : ((String)->())? {
		didSet {
			idSource.debugOut = debugOut
			connection?.debugOut = debugOut
		}
    }
	
	public init(client: MQTTClientParams, host: MQTTHostParams = MQTTHostParams(), reconnect: MQTTReconnectParams = MQTTReconnectParams()) {
		self.client = client
		self.host = host
		self.reconnect = reconnect
		idSource = MQTTMessageIdSource()
		self.publisher = MQTTPublisher(idSource: idSource, qos2Mode: client.qos2Mode)
		self.subscriber = MQTTSubscriber(idSource: idSource)
		self.distributer = MQTTDistributor(idSource: idSource)
		
		resendTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
		resendTimer.schedule(deadline: .now() + client.resendPulseInterval, repeating: client.resendPulseInterval, leeway: .milliseconds(250))
		resendTimer.setEventHandler { [weak self] in
			self?.resendPulse()
		}
		
		publisher.delegate = self
		subscriber.delegate = self
		distributer.delegate = self
	}
	
	public func start() {
		retry = MQTTRetryConnection(spec: reconnect, attemptConnect: { [weak self] in
			self?.makeConnection()
		})
		retry?.start()
	}
	
	public func stop() {
		retry = nil
		connection = nil
		// connection does not call delegate in deinit
		doDisconnect(reason: .manual, error: nil)
	}
	
	private func makeConnection() {
		delegate?.mqttConnectAttempted(client: self)
		connection = MQTTConnection(hostParams: host, clientPrams: client)
		connection?.debugOut = debugOut
		connection?.delegate = self
	}
	
	private func resendPulse() {
		publisher.resendPulse()
		subscriber.resendPulse()
		distributer.resendPulse()
	}
	
	private func unhandledPacket(packet: MQTTPacket) {
		debugOut?("* MQTT Unhandled: \(type(of:packet))")
	}
}

extension MQTTClient: MQTTBridge {
	public func publish(_ pubMsg: MQTTPubMsg, completion: ((Bool)->())?) {
		publisher.publish(pubMsg: pubMsg, completion: completion)
	}
	
	public func subscribe(topics: [(String, MQTTQoS)], completion: ((Bool)->())?) -> MQTTSubscription {
		return subscriber.subscribe(topics: topics, completion: completion)
	}
	
	public func registerTopic(path: String, action: @escaping (MQTTMessage)->()) -> MQTTRegistration {
		return distributer.registerTopic(path: path, action: action)
	}
}

extension MQTTClient: MQTTConnectionDelegate {
	func mqttDisconnected(_ connection: MQTTConnection, reason: MQTTConnectionDisconnect, error: Error?) {
		doDisconnect(reason: reason, error: error)
	}
	
	private func doDisconnect(reason: MQTTConnectionDisconnect, error: Error?) {
		resendTimer.suspend()
		var manual = false
		if case .manual = reason {
			manual = true
		}
		publisher.disconnected(cleanSession: client.cleanSession, manual: manual)
		subscriber.disconnected(cleanSession: client.cleanSession, manual: manual)
		distributer.disconnected(cleanSession: client.cleanSession, manual: manual)
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
		retry?.connected = true
		delegate?.mqttConnected(client: self)
		publisher.connected(cleanSession: connection.cleanSession, present: present)
		subscriber.connected(cleanSession: connection.cleanSession, present: present)
		distributer.connected(cleanSession: connection.cleanSession, present: present)
		resendTimer.resume()
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

extension MQTTClient: MQTTPublisherDelegate, MQTTSubscriptionDelegate, MQTTDistributorDelegate {
	func send(packet: MQTTPacket) -> Bool {
		return connection?.send(packet: packet) ?? false
	}
	
	// TODO: get Packet creation and marshalling in background thread
	// call completion(false) if no "delegate"
	/*
	func doIt<T: MQTTPacket>(factory: @escaping ()->T, writer: @escaping (Data)->Bool, completion: ((T, Bool)->())?) {
		DispatchQueue.global().async {
			let packet = factory()
			let data = MQTTPacketFactory().write(packet)
			let success = writer(data)
			completion?(packet, success)
		}
	}
	*/
	
	func unhandledMessage(message: MQTTMessage) {
		delegate?.mqttUnhandledMessage(message: message)
	}
	
	func subscriptionChanged(subscription: MQTTSubscriptionDetail, status: MQTTSubscriptionStatus) {
		delegate?.mqttSubscriptionChanged(client: self, subscription: subscription, status: status)
	}
}
