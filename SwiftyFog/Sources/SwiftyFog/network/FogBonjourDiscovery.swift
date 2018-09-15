//
//  BonjourDiscovery.swift
//  TrainControl
//
//  Created by David Giovannini on 8/5/18.
//  Copyright © 2018 Object Computing Inc. All rights reserved.
//

#if os(iOS) || os(macOS)

import Foundation // NetServiceBrowser
// Not available on watch

public enum BonjourDiscoveryOperation: String {
    case SearchStopped
    case DidNotSearched
    case NotResolved
}

public protocol BonjourDiscoveryDelegate: class {
    func bonjourDiscovery(_ bonjourDiscovery: FogBonjourDiscovery, didFailedAt: BonjourDiscoveryOperation, withErrorDict: [String: NSNumber]?)
	func bonjourDiscovery(_ bonjourDiscovery: FogBonjourDiscovery, didFindService: NetService, atHosts host: [(String, UInt16)])
	func bonjourDiscovery(_ bonjourDiscovery: FogBonjourDiscovery, didRemovedService: NetService)
	
	func browserDidStart(_ bonjourDiscovery: FogBonjourDiscovery)
	func browserDidStop(_ bonjourDiscovery: FogBonjourDiscovery)
	func bonjourDiscovery(_ bonjourDiscovery: FogBonjourDiscovery, serviceDidUpdateTXT: NetService, TXT: Data)
}

public class FogBonjourDiscovery: NSObject {
	private let svr = NetServiceBrowser()
	private var services = Set<NetService>()
    private let type: String
    private let proto: String
    private let domain: String
	
    public weak var delegate: BonjourDiscoveryDelegate?
	
    public init(type: String, proto: String, domain: String = "") {
        self.type = type
        self.proto = proto
        self.domain = domain
        super.init()
        svr.delegate = self
    }
	
    public func start(runloop: RunLoop = RunLoop.current) {
		svr.searchForServices(ofType: "_\(type)._\(proto)", inDomain: domain)
		svr.schedule(in: runloop, forMode: RunLoop.Mode.default)
    }
	
    public func stop() {
        svr.stop()
    }
}

extension FogBonjourDiscovery: NetServiceBrowserDelegate {
	public func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        self.services.remove(service)
		self.delegate?.bonjourDiscovery(self, didRemovedService: service)
    }
	
	public func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
		delegate?.browserDidStart(self)
    }
	
	public func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser){
		delegate?.browserDidStop(self)
    }
	
	public func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        delegate?.bonjourDiscovery(self, didFailedAt: .DidNotSearched, withErrorDict: errorDict)
    }
	
	public func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool){
        service.delegate = self
		service.resolve(withTimeout: 0.0)
		service.schedule(in: RunLoop.current, forMode: RunLoop.Mode.default)
        services.insert(service)
    }
	
	public func netServiceBrowser(_ browser: NetServiceBrowser, didFindDomain domainString: String, moreComing: Bool) {
	}

    public func netServiceBrowser(_ browser: NetServiceBrowser, didRemoveDomain domainString: String, moreComing: Bool) {
    }
}

extension FogBonjourDiscovery: NetServiceDelegate {
	public func netServiceDidResolveAddress(_ sender: NetService) {
        var ips = [(String, UInt16)]()
        if let addresses = sender.addresses, addresses.count > 0 {
			for address in addresses {
				address.withUnsafeBytes { (ptr: UnsafePointer<sockaddr_in>) in
					let inetAddress: sockaddr_in = ptr.pointee
					if inetAddress.sin_family == __uint8_t(AF_INET) {
						if let ip = String(cString: inet_ntoa(inetAddress.sin_addr), encoding: .ascii) {
							ips.append((ip, inetAddress.sin_port.bigEndian))
						}
					}
					else if inetAddress.sin_family == __uint8_t(AF_INET6) {
						ptr.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) { ptr in
							let inetAddress6: sockaddr_in6 = ptr.pointee
							var addr = inetAddress6.sin6_addr
							var ipStringBuffer = Data(count: Int(INET6_ADDRSTRLEN))
							ipStringBuffer.withUnsafeMutableBytes { (ipStringBuffer: UnsafeMutablePointer<Int8>) in
								if let ipString = inet_ntop(Int32(inetAddress6.sin6_family), &addr, ipStringBuffer, __uint32_t(INET6_ADDRSTRLEN)) {
									if let ip = String(cString: ipString, encoding: .ascii) {
										ips.append((ip, inetAddress6.sin6_port.bigEndian))
									}
								}
							}
						}
					}
				}
			}
			delegate?.bonjourDiscovery(self, didFindService: sender, atHosts: ips)
		}
    }
	
    public func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        delegate?.bonjourDiscovery(self, didFailedAt: .NotResolved, withErrorDict: errorDict)
    }
	
	public func netService(_ sender: NetService, didUpdateTXTRecord data: Data) {
		delegate?.bonjourDiscovery(self, serviceDidUpdateTXT: sender, TXT: data)
    }
	
    public func netServiceWillPublish(_ sender: NetService) {
    }
	
    public func netServiceDidPublish(_ sender: NetService) {
    }
	
    public func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
    }
	
    public func netServiceWillResolve(_ sender: NetService) {
    }
	
    public func netServiceDidStop(_ sender: NetService) {
    }
	
    public func netService(_ sender: NetService, didAcceptConnectionWith inputStream: InputStream, outputStream: OutputStream) {
    }
}

#endif
