//
//  MQTTConnectedState.swift
//  SwiftyFog
//
//  Created by David Giovannini on 9/7/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

public enum MQTTConnectedState: CustomStringConvertible {
	case started
	case connected(cleanSession: Bool, connectedAsPresent: Bool, isInitial: Bool, connectionCounter: Int)
	case pinged(MQTTPingStatus)
	case disconnected(cleanSession: Bool, reason: MQTTConnectionDisconnect, error: Error?)
	case retry(Int, Int, Int, MQTTReconnectParams) // connection counter, rescus counter, attempt counter
	case retriesFailed(Int, Int, MQTTReconnectParams) // connection counter, rescus counter
	
	public var description: String {
		switch self {
			case .started:
				return "Started"
			case .connected(_, _, _, let counter):
				return "Connected \(counter)"
			case .pinged(let status):
				return "Ping \(status)"
			case .retry(_, let rescus, let attempt, _):
				return "Connection Attempt \(rescus).\(attempt)"
			case .retriesFailed(let counter, let rescus, _):
				return "Connection Failed \(counter).\(rescus)"
			case .disconnected(_, let reason, let error):
				return "Disconnected \(reason) \(error?.localizedDescription ?? "")"
		}
	}
}
