//
//  MQTTReconnectParams.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/26/17.
//

import Foundation

public struct MQTTReconnectParams {
    public var retryCount: Int
    public var retryTimeInterval: TimeInterval
    public var resuscitateTimeInterval: TimeInterval
	
    public init(retryCount: Int = 3, retryTimeInterval: TimeInterval = 1.0, resuscitateTimeInterval: TimeInterval = 10.0) {
		self.retryCount = retryCount
		self.retryTimeInterval = retryTimeInterval
		self.resuscitateTimeInterval = resuscitateTimeInterval
    }
}
