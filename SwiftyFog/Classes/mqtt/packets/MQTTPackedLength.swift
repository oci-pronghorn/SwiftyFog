//
//  MQTTPackedLength.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/15/17.
//

import Foundation

struct MQTTPackedLength {
	static let min: Int = 0
	static let max: Int = 268435455
	static let minLen = 1
	static let maxLen = MemoryLayout<UInt32>.size
	
	private init() {}

    static func bytesRquired(for length: Int) -> Int {
		if length <= 127 {
			return 1
		}
		else if length <= 16383 {
			return 2
		}
		else if length <= 2097151 {
			return 3
		}
		// <= max
		return 4
    }
	
	static func replace(in data: inout Data, at: Int, length: Int) {
        var lengthOfRemainingData = length
        var cursor = at
        repeat {
            var digit = UInt8(lengthOfRemainingData % 128)
            lengthOfRemainingData /= 128
            if lengthOfRemainingData > 0 {
                digit |= 0x80
            }
            data[cursor] = digit
            cursor += 1
        } while lengthOfRemainingData > 0
    }
	
	static func read(from read: StreamReader) -> Int? {
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
		return value
	}
}
