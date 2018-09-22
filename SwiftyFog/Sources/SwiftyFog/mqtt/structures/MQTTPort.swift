//
//  MQTTPort.swift
//  SwiftyFog
//
//  Created by David Giovannini on 9/15/18.
//  Copyright © 2018 Object Computing Inc. All rights reserved.
//

public enum MQTTPort {
	case standard
	case ssl
	case other(UInt16)
	
	public init(number: UInt16) {
		switch number {
			case 1883:
				self = .standard
			case 8883:
				self = .ssl
			default:
				self = .other(number)
		}
	}
	
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
