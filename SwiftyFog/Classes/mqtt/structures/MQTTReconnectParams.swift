//
//  MQTTReconnectParams.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/26/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

public struct MQTTReconnectParams {
    public var attemptCount: Int
    public var retryTimeInterval: TimeInterval
    public var resuscitateTimeInterval: TimeInterval
	
    public init(attemptCount: Int = 3, retryTimeInterval: TimeInterval = 1.0, resuscitateTimeInterval: TimeInterval = 10.0) {
		self.attemptCount = attemptCount
		self.retryTimeInterval = retryTimeInterval
		self.resuscitateTimeInterval = resuscitateTimeInterval
    }
}
