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
	
	mutating func mqttAppend(_ value: Data) {
		self.fogAppend(UInt16(value.count))
		self.append(value)
	}
	
	// TODO: make generic and faster
	mutating func mqttInsertRemaining(at: Int, length: Int) -> Int {
		var c = 0
        var lengthOfRemainingData = length
        repeat {
            var digit = UInt8(lengthOfRemainingData % 128)
            lengthOfRemainingData /= 128
            if lengthOfRemainingData > 0 {
                digit |= 0x80
            }
            self[at] = digit
            //append(&digit, count: 1)
            c += 1
        } while lengthOfRemainingData > 0
        return c
    }
	
	static func readMqttPackedLength(from read: StreamReader) -> Int? {
		var multiplier = 1
		var value = 0
		var encodedByte: UInt8 = 0
		repeat {
			let bytesRead = read(&encodedByte, 1)
			if bytesRead < 0 {
				return nil
			}
			value += (Int(encodedByte) & 127) * multiplier
			multiplier *= 128
		} while ((Int(encodedByte) & 128) != 0)
		return value <= 128*128*128 ? value : nil
	}
}
