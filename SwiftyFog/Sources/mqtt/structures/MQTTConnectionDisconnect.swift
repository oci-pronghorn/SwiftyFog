//
//  MQTTConnectionDisconnect.swift
//  SwiftyFog
//
//  Created by David Giovannini on 9/7/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

// The following are reasons for disconnection from broker
public enum MQTTConnectionDisconnect {
	case stopped // by client
	case socket // by connection
	case handshake(MQTTConnAckResponse) // by connection
	case brokerNotAlive // by connection
	case failedRead // from stream
	case failedWrite // from stream
	case serverDisconnectedUs // from stream
}
