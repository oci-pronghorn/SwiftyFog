//
//  NetworkReachabilityStub.swift
//  SwiftyFog_iOS
//
//  Created by David Giovannini on 11/27/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

public final class NetworkReachability {

    public typealias NetworkReachable = (NetworkReachabilityStatus) -> ()

    public var status: NetworkReachabilityStatus { return .wifi }

    public init(queue: DispatchQueue = DispatchQueue.global(), allowsCellularConnection: Bool = true, hostname: String? = nil) {
    }

    public func start(reachable: NetworkReachable? = nil) {
		reachable?(.wifi)
    }

    public func stop() {
    }
}


public enum NetworkReachabilityStatus : CustomStringConvertible {
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
