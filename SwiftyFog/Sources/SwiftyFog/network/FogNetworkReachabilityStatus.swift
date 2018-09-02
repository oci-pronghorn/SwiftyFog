//
//  FogNetworkReachabilityStatus.swift
//  SwiftyFog
//
//  Created by David Giovannini on 7/10/18.
//  Copyright © 2018 Object Computing Inc. All rights reserved.
//

public enum FogNetworkReachabilityStatus : CustomStringConvertible {
	case none, wifi, cellular, unknown
	
	public var description: String {
		switch self {
		case .cellular: return "Cellular"
		case .wifi: return "WiFi"
		case .none: return "No Connection"
		case .unknown: return "Unknown"
		}
	}
}
