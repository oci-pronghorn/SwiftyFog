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
}

public class MQTTClient {
	private var publisher: MQTTPublisher
	private var connection: MQTTConnection?
	
	public init() {
		let idSource = MQTTMessageIdSource()
		self.publisher = MQTTPublisher(idSource: idSource)
		publisher.delegate = self
	}
	
	public func start() {
		var host = MQTTHostParams()
		host.host = "thejoveexpress.local"
		let client = MQTTClientParams(clientID: "SwiftyFog")
		connection = MQTTConnection(hostParams: host, clientPrams: client)
		connection?.delegate = self
	}
	
	public func stop() {
		connection = nil
	}
	
	public func publish(topic: String, payload: Data, retain: Bool = false, qos: MQTTQoS = .atMostOnce, completion: ((Bool)->())?) {
		publisher.publish(topic: topic, payload: payload, retain: retain, qos: qos, completion: completion)
	}
}

extension MQTTClient: MQTTConnectionDelegate {
	public func mqttDiscconnected(_ connection: MQTTConnection, reason: MQTTConnectionDisconnect, error: Error?) {
		print("\(Date.NowInSeconds()): MQTT Discconnected \(reason) \(error?.localizedDescription ?? "")")
		publisher.disconnected(cleanSession: connection.cleanSession, final: reason == .shutdown)
		// TODO: New language rules. I need to rethink delegate calls from deinit - as I should :-)
		if reason != .shutdown {
			self.connection = nil
		}
	}
	
	public func mqttConnected(_ connection: MQTTConnection) {
		print("\(Date.NowInSeconds()): MQTT Connected")
		publisher.connected(cleanSession: connection.cleanSession)
	}
	
	public func mqttPinged(_ connection: MQTTConnection, dropped: Bool) {
		print("\(Date.NowInSeconds()): MQTT Pinged \(!dropped)")
	}
	
	public func mqttPingAcknowledged(_ connection: MQTTConnection) {
		print("\(Date.NowInSeconds()): MQTT Acknowledged")
	}
	
	public func mqttReceived(_ connection: MQTTConnection, packet: MQTTPacket) {
		let _ = publisher.receive(packet: packet)
	}
}

extension MQTTClient: MQTTPublisherDelegate {
	public func send(packet: MQTTPacket) -> Bool {
		return connection?.send(packet: packet) ?? false
	}
}
