//
//  NetworkReachabilityStub.swift
//  SwiftyFog_iOS
//
//  Created by David Giovannini on 11/27/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

// TODO: this is used for testing and watch. We need soemthing better for watch.

public final class FogNetworkReachability {

    public typealias NetworkReachable = (FogNetworkReachabilityStatus) -> ()

    public var status: FogNetworkReachabilityStatus { return .wifi }

    public init(queue: DispatchQueue = DispatchQueue.global(), allowsCellularConnection: Bool = true, hostname: String? = nil) {
    }

    public func start(reachable: NetworkReachable? = nil) {
		reachable?(.wifi)
    }

    public func stop() {
    }
}
