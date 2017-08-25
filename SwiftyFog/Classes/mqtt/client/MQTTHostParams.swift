//
//  MQTTHostParams.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/25/17.
//

import Foundation

public enum MQTTPort {
	case standard
	case ssl
	case other(UInt16)
	
	public var number: UInt16 {
		switch self {
			case .standard:
				return 1883
			case .ssl:
				return 8883
			case .other(let number):
				return number
		}
	}
}

public struct MQTTHostParams {
    public var host: String
    public var port: UInt16
    public var ssl: Bool
    public var timeout: TimeInterval
	
    public init(host: String = "localhost", port: MQTTPort = .standard, ssl: Bool = false, timeout: TimeInterval = 10.0) {
		self.host = host
		self.port = port.number
		self.ssl = ssl
		self.timeout = timeout
    }
}
