//
//  MQTTHostParams.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/25/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation // StreamSocketSecurityLevel

public struct MQTTHostParams {
    public let host: String
    public let port: UInt16
    public let ssl: StreamSocketSecurityLevel?
	
    public var localHostName: String {
		#if os(OSX)
			return Host.current().localizedName ?? ""
		#else
			return "" // TODO
		#endif
    }
	
    public init(host: String = "localhost", port: MQTTPort = .standard, ssl: StreamSocketSecurityLevel? = nil) {
		self.host = host
		self.port = port.number
		self.ssl = ssl
    }
}
