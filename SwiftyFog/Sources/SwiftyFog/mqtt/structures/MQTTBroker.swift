//
//  MQTTBroker.swift
//  SwiftyFog
//
//  Created by David Giovannini on 9/15/18.
//  Copyright © 2018 Object Computing Inc. All rights reserved.
//

fileprivate extension String {
	func firstPart() -> String {
		if let idx = self.firstIndex(of: ".") {
			return String(self.prefix(upTo: idx))
		}
		return self
	}
}

public struct MQTTBroker {
	public let hostName: String
	public let addreses : [(address: String, port: MQTTPort)]
	public var name: String { return hostName.firstPart() }
	
	public init(hostName: String, addreses : [(address: String, port: MQTTPort)]) {
		self.hostName = hostName
		self.addreses = addreses
	}
	
	public init(hostName: String, port: MQTTPort = MQTTPort.standard) {
		self.hostName = hostName
		self.addreses = [(address: hostName, port: port)]
	}
}
