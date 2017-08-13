//
//  MQTTPacketType.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/9/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

enum MQTTPacketType: UInt8 {
    case connect        = 0x01
    case connAck        = 0x02
    case publish        = 0x03
    case pubAck         = 0x04
    case pubRec         = 0x05
    case pubRel         = 0x06
    case pubComp        = 0x07
    case subscribe      = 0x08
    case subAck         = 0x09
    case unSubscribe    = 0x0A
    case unSubAck       = 0x0B
    case pingReq        = 0x0C
    case pingResp       = 0x0D
    case disconnect     = 0x0E
}
