//
//  MQTTPingStatus.swift
//  SwiftyFog
//
//  Created by David Giovannini on 9/7/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

public enum MQTTPingStatus: String {
	case notConnected
	case sent
	case skipped
	case ack
	case serverDied
}
