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
	private var mqtt: MQTTConnection?
	
	public init() {
	}
	
	public func start() {
		var host = MQTTHostParams()
		host.host = "thejoveexpress.local"
		let client = MQTTClientParams(clientID: "SwiftyFog")
		mqtt = MQTTConnection(hostParams: host, clientPrams: client)
		mqtt?.delegate = self
	}
	
	public func stop() {
		mqtt = nil
	}
}

extension MQTTClient: MQTTConnectionDelegate {
	public func mqttDiscconnected(_ connection: MQTTConnection, reason: MQTTConnectionDisconnect, error: Error?) {
		print("\(Date.NowInSeconds()): MQTT Discconnected \(reason) \(error?.localizedDescription ?? "")")
		// TODO: New language rules. I need to rethink delegate calls from deinit - as I should :-)
		if reason != .shutdown {
			mqtt = nil
		}
	}
	
	public func mqttConnected(_ connection: MQTTConnection) {
		print("\(Date.NowInSeconds()): MQTT Connected")
	}
	
	public func mqttPinged(_ connection: MQTTConnection, dropped: Bool) {
		print("\(Date.NowInSeconds()): MQTT Pinged \(!dropped)")
	}
	
	public func mqttPingAcknowledged(_ connection: MQTTConnection) {
		print("\(Date.NowInSeconds()): MQTT Acknowledged")
	}
}
