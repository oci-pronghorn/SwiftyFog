//
//  MQTTConnAckResponse.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/9/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

enum MQTTConnAckResponse: UInt8, Error {
    case connectionAccepted     = 0x00
    case badProtocol            = 0x01
    case clientIDRejected       = 0x02
    case serverUnavailable      = 0x03
    case badUsernameOrPassword  = 0x04
    case notAuthorized          = 0x05
}