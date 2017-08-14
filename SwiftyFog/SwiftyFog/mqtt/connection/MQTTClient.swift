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

public class MQTTClient {
	private var reconnect: MQTTReconnect
	private var publisher: MQTTPublisher
	private var subscriber: MQTTSubscriber
	private var distributer: MQTTDistributor
	private var connection: MQTTConnection?
	
	public init(reconnect: MQTTReconnect = MQTTReconnect()) {
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
		var host = MQTTHostParams()
		//host.host = "thejoveexpress.local"
		let client = MQTTClientParams(clientID: "SwiftyFog")
		connection = MQTTConnection(hostParams: host, clientPrams: client)
		connection?.delegate = self
	}
	
	public func stop() {
		connection = nil
	}
	
	public func publish(
			topic: String,
			payload: Data,
			retain: Bool = false,
			qos: MQTTQoS = .atMostOnce,
			retry: PublishRetry = PublishRetry(),
			completion: ((Bool)->())?) {
		publisher.publish(topic: topic, payload: payload, retain: retain, qos: qos, retry: retry, completion: completion)
	}
	
	public func subscribe(topics: [String: MQTTQoS], completion: ((Bool)->())?) -> MQTTSubscription {
		return subscriber.subscribe(topics: topics, completion: completion)
	}
	
	public func registerTopic(path: String, action: ()->()) {
		return distributer.registerTopic(path: path, action: action)
	}
	
	private func unhandledPacket(packet: MQTTPacket) {
		print("Unhandled")
	}
}

extension MQTTClient: MQTTConnectionDelegate {
	public func mqttDiscconnected(_ connection: MQTTConnection, reason: MQTTConnectionDisconnect, error: Error?) {
		print("\(Date.NowInSeconds()): MQTT Discconnected \(reason) \(error?.localizedDescription ?? "")")
		publisher.disconnected(cleanSession: connection.cleanSession, final: reason == .shutdown)
		subscriber.disconnected(cleanSession: connection.cleanSession, final: reason == .shutdown)
		distributer.disconnected(cleanSession: connection.cleanSession, final: reason == .shutdown)
		// TODO: New language rules. I need to rethink delegate calls from deinit - as I should :-)
		if reason != .shutdown {
			self.connection = nil
		}
	}
	
	public func mqttConnected(_ connection: MQTTConnection) {
		print("\(Date.NowInSeconds()): MQTT Connected")
		publisher.connected(cleanSession: connection.cleanSession)
		subscriber.connected(cleanSession: connection.cleanSession)
		distributer.connected(cleanSession: connection.cleanSession)
	}
	
	public func mqttPinged(_ connection: MQTTConnection, dropped: Bool) {
		print("\(Date.NowInSeconds()): MQTT Pinged \(!dropped)")
	}
	
	public func mqttPingAcknowledged(_ connection: MQTTConnection) {
		print("\(Date.NowInSeconds()): MQTT Acknowledged")
	}
	
	public func mqttReceived(_ connection: MQTTConnection, packet: MQTTPacket) {
		var handled = publisher.receive(packet: packet)
		if handled == false {
			handled = subscriber.receive(packet: packet)
			if handled == false {
				handled = distributer.receive(packet: packet)
				if handled == false {
					unhandledPacket(packet: packet)
				}
			}
		}
	}
}

extension MQTTClient: MQTTPublisherDelegate, MQTTSubscriptionDelegate, MQTTDistributorDelegate {
	public func send(packet: MQTTPacket) -> Bool {
		return connection?.send(packet: packet) ?? false
	}
}
