//
//  NetworkReachability.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/12/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import SystemConfiguration
import Foundation

public final class NetworkReachability {
    public typealias NetworkReachable = (NetworkReachabilityStatus) -> ()

    private var reachable: NetworkReachable?
    private let queue: DispatchQueue
    private let allowsCellularConnection: Bool
    private let reachabilityRef: SCNetworkReachability?
    private var previousFlags: SCNetworkReachabilityFlags?
    private var notifierRunning = false
	
    public var status: NetworkReachabilityStatus {
        return NetworkReachabilityStatus(reachabilityRef?.flags, allowsCellularConnection)
    }
	
    public init(
			queue: DispatchQueue = DispatchQueue.global(),
			allowsCellularConnection: Bool = true,
			hostname: String? = nil) {
		self.queue = queue
		self.allowsCellularConnection = allowsCellularConnection
		if let hostname = hostname {
			self.reachabilityRef = SCNetworkReachabilityCreateWithName(nil, hostname)
		}
		else {
			var zeroAddress = sockaddr()
			zeroAddress.sa_len = UInt8(MemoryLayout<sockaddr>.size)
			zeroAddress.sa_family = sa_family_t(AF_INET)
			self.reachabilityRef = SCNetworkReachabilityCreateWithAddress(nil, &zeroAddress)
		}
	}
	
	public func start(reachable: NetworkReachable? = nil) {
		self.reachable = reachable
		self.startNotifier()
        self.queue.async {
            self.reachabilityChanged()
        }
	}
	
	public func stop() {
		self.stopNotifier()
	}
	
    deinit {
        stopNotifier()
    }
}

private extension NetworkReachability {
    private func startNotifier() {
        guard !notifierRunning else { return }
        if let reachabilityRef = reachabilityRef {
			var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
			context.info = UnsafeMutableRawPointer(Unmanaged<NetworkReachability>.passUnretained(self).toOpaque())
			var success = SCNetworkReachabilitySetCallback(reachabilityRef, {(_, _, info) in
				guard let info = info else { return }
				let reachability = Unmanaged<NetworkReachability>.fromOpaque(info).takeUnretainedValue()
				reachability.reachabilityChanged()
			}, &context)
			if success {
				success = SCNetworkReachabilitySetDispatchQueue(reachabilityRef, self.queue)
			}
			if success {
				notifierRunning = true
			}
		}
    }
	
    private func reachabilityChanged() {
		let flags = reachabilityRef?.flags
        guard previousFlags != flags else { return }
        previousFlags = flags
        let status = self.status
		self.reachable?(status)
    }
	
    private func stopNotifier() {
        defer { notifierRunning = false }
		previousFlags = nil
        reachabilityRef?.closeCallbacks()
    }
}

public enum NetworkReachabilityStatus: CustomStringConvertible {
	case none, wifi, cellular, unknown
	
	fileprivate init(_ flags: SCNetworkReachabilityFlags?, _ allowsCellularConnection: Bool) {
		guard let flags = flags else { self = .unknown; return }
		guard flags.isReachableFlagSet else { self = .none; return }

		// If we're reachable, but not on an iOS device (i.e. simulator), we must be on WiFi
		guard flags.isRunningOnDevice else { self = .wifi; return }

		var connection = NetworkReachabilityStatus.none
		
		if !flags.isConnectionRequiredFlagSet {
			connection = .wifi
		}
		
		if flags.isConnectionOnTrafficOrDemandFlagSet {
			if !flags.isInterventionRequiredFlagSet {
				connection = .wifi
			}
		}
		
		if flags.isOnWWANFlagSet {
			if !allowsCellularConnection {
				connection = .none
			} else {
				connection = .cellular
			}
		}
		self = connection
	}
	
	public var description: String {
		switch self {
		case .cellular: return "Cellular"
		case .wifi: return "WiFi"
		case .none: return "No Connection"
		case .unknown: return "Unknown"
		}
	}
}

fileprivate extension SCNetworkReachability {
    fileprivate var flags: SCNetworkReachabilityFlags {
        var flags = SCNetworkReachabilityFlags()
        if SCNetworkReachabilityGetFlags(self, &flags) {
            return flags
        } else {
            return SCNetworkReachabilityFlags()
        }
    }
	
    fileprivate func closeCallbacks() {
        SCNetworkReachabilitySetCallback(self, nil, nil)
        SCNetworkReachabilitySetDispatchQueue(self, nil)
    }
}

extension SCNetworkReachabilityFlags: CustomStringConvertible {
    fileprivate var isRunningOnDevice: Bool {
        #if targetEnvironment(simulator)
            return false
        #else
            return true
        #endif
    }
	
    fileprivate var isOnWWANFlagSet: Bool {
        #if os(iOS)
            return self.contains(.isWWAN)
        #else
            return false
        #endif
    }
    fileprivate var isReachableFlagSet: Bool {
        return self.contains(.reachable)
    }
    fileprivate var isConnectionRequiredFlagSet: Bool {
        return self.contains(.connectionRequired)
    }
    fileprivate var isInterventionRequiredFlagSet: Bool {
        return self.contains(.interventionRequired)
    }
    fileprivate var isConnectionOnTrafficFlagSet: Bool {
        return self.contains(.connectionOnTraffic)
    }
    fileprivate var isConnectionOnDemandFlagSet: Bool {
        return self.contains(.connectionOnDemand)
    }
    fileprivate var isConnectionOnTrafficOrDemandFlagSet: Bool {
        return !self.intersection([.connectionOnTraffic, .connectionOnDemand]).isEmpty
    }
    fileprivate var isTransientConnectionFlagSet: Bool {
        return self.contains(.transientConnection)
    }
    fileprivate var isLocalAddressFlagSet: Bool {
        return self.contains(.isLocalAddress)
    }
    fileprivate var isDirectFlagSet: Bool {
        return self.contains(.isDirect)
    }
    fileprivate var isConnectionRequiredAndTransientFlagSet: Bool {
        return self.intersection([.connectionRequired, .transientConnection]) == [.connectionRequired, .transientConnection]
    }
	
	public var description: String {
        let W = isRunningOnDevice ? (isOnWWANFlagSet ? "W" : "-") : "X"
        let R = isReachableFlagSet ? "R" : "-"
        let c = isConnectionRequiredFlagSet ? "c" : "-"
        let t = isTransientConnectionFlagSet ? "t" : "-"
        let i = isInterventionRequiredFlagSet ? "i" : "-"
        let C = isConnectionOnTrafficFlagSet ? "C" : "-"
        let D = isConnectionOnDemandFlagSet ? "D" : "-"
        let l = isLocalAddressFlagSet ? "l" : "-"
        let d = isDirectFlagSet ? "d" : "-"
        return "\(W)\(R) \(c)\(t)\(i)\(C)\(D)\(l)\(d)"
    }
}
