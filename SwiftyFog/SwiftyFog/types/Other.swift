//
//  Data+.swift
//  SwiftyFog
//
//  Created by David Giovannini on 9/8/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

extension Date {
	public static func nowInSeconds() -> Int64 {
		return Int64(Date().timeIntervalSince1970.rounded())
	}
}

extension Dictionary {
	public mutating func computeIfAbsent(_ key: Key, _ compute: (Key)->(Value), _ update: (Key, inout Value)->()) {
		if self[key] != nil {
			update(key, &(self[key]!))
		}
		else {
			let value = compute(key)
			self[key] = value
		}
	}
}

public extension FloatingPoint {
	var degreesToRadians: Self { return self * .pi / 180 }
	var radiansToDegrees: Self { return self * 180 / .pi }
}

public extension CharacterSet {
    /// extracting characters
    public func allCharacters() -> [Character] {
        var allCharacters = [Character]()
        for plane: UInt8 in 0 ... 16 where hasMember(inPlane: plane) {
            for unicode in UInt32(plane) << 16 ..< UInt32(plane + 1) << 16 {
                if let uniChar = UnicodeScalar(unicode), contains(uniChar) {
                    allCharacters.append(Character(uniChar))
                }
            }
        }
        return allCharacters
    }

    /// building random string of desired length
    public func randomString(length: Int) -> String {
        let charArray = allCharacters()
        let charArrayCount = UInt32(charArray.count)
        var randomString = ""
        for _ in 0 ..< length {
            randomString += String(charArray[Int(arc4random_uniform(charArrayCount))])
        }
        return randomString
    }
}
