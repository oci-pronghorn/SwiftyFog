//
//  MQTTAuthentication.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/25/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

public struct MQTTAuthentication {
    public var username: String?
    public var password: String?
	
    public init(username: String? = nil, password: String? = nil) {
		self.username = username
		self.password = password
    }
}
