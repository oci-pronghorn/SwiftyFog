//
//  MQTTQoS.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/9/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

public enum MQTTQoS: UInt8 {
    case atMostOnce     = 0x00
    case atLeastOnce    = 0x01
    case exactlyOnce    = 0x02
}

public enum Qos2Mode {
	case lowLatency
	case assured
}
