//
//  MQTTRoutingParams.swift
//  SwiftyFog_iOS
//
//  Created by David Giovannini on 11/22/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation // TimeInterval

public struct MQTTRoutingParams {
	// The spec states that business logic may be invoked on either the 1st or 2nd ack
    public var qos2Mode: Qos2Mode = .lowLatency
    // The spec states that retransmission of disconnected pubs is up to business logic
	public var queuePubOnDisconnect: MQTTQoS? = nil
	// Spec says we must resend only on reconnect not-clean-session.
	// A non-zero interval will resend while connected
    public var resendPulseInterval: TimeInterval = 5.0
    public var resendLimit: UInt64 = UInt64.max
	
    public init() {
    }
}
