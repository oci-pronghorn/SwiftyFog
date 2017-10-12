//
//  MQTTConnectedState.swift
//  SwiftyFog
//
//  Created by David Giovannini on 9/7/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

public enum MQTTConnectedState {
	case started
	case connected(Int)
	case pinged(MQTTPingStatus)
	case disconnected(reason: MQTTConnectionDisconnect, error: Error?)
	case retry(Int, Int, Int, MQTTReconnectParams) // connection counter, rescus counter, attempt counter
	case retriesFailed(Int, Int, MQTTReconnectParams) // connection counter, rescus counter
}
