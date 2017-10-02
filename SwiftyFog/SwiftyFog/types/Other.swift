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
