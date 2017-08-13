//
//  FogRational.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/9/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

struct FogRational<T: FixedWidthInteger> : Equatable, FogExternalizable {
	var num: T = 0
	var den: T = 1
	
	init() {
		self.num = 0
		self.den = 1
	}
	
	init(num: T, den: T) {
		self.num = num
		self.den = den
	}
	
	init(data: Data, cursor: inout Int) {
		self.num = data.fogExtract(&cursor)
		self.den = data.fogExtract(&cursor)
	}
	
	func writeTo(data: inout Data) {
		data.fogAppend(num)
		data.fogAppend(den)
	}
	
	static func ==(lhs: FogRational<T>, rhs: FogRational<T>) -> Bool {
		return lhs.num == rhs.num && lhs.den == rhs.den
	}
}
