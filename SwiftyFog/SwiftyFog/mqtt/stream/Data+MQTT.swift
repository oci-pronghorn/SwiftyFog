//
//  Data+MQTT.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/12/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

extension Data {
	mutating func mqttAppend <T: FixedWidthInteger> (_ rhs: T) {
		self.fogAppend(rhs)
	}
	
	mutating func mqttAppend(_ rhs: String) {
		self.fogAppend(rhs)
	}
	
	public mutating func mqttAppend(_ value: Data) {
		self.fogAppend(UInt16(value.count))
		self.append(value)
	}
	
	mutating func mqttAppendRemaining(length: Int) {
        var lengthOfRemainingData = length
        repeat {
            var digit = UInt8(lengthOfRemainingData % 128)
            lengthOfRemainingData /= 128
            if lengthOfRemainingData > 0 {
                digit |= 0x80
            }
            append(&digit, count: 1)
        } while lengthOfRemainingData > 0
    }
}
