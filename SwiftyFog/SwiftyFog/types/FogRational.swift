//
//  FogRational.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/9/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation // Data

public struct FogRational<T: FixedWidthInteger> : Equatable, FogExternalizable, CustomStringConvertible {
    public typealias ValueType = T
	public var num: T = 0
	public var den: T = 1

	public init() {
		self.num = 0
		self.den = 1
	}
	
	public init(num: T, den: T) {
		self.num = num
		self.den = den
	}
	
	public init?(data: Data, cursor: inout Int) {
		self.num = data.fogExtract(&cursor)
		self.den = data.fogExtract(&cursor)
		if self.den == 0 {
			return nil
		}
	}

	public var description: String {
		return "\(num)/\(den)"
	}
	/*
	public var ratio: Double! {
		if let num = Double(exactly: self.num), let den = Double(exactly: self.den) {
			return num / den
		}
		return nil
	}
	*/
	public var fogSize: Int {
		return num.fogSize + den.fogSize
	}
	
	public func writeTo(data: inout Data) {
		data.fogAppend(num)
		data.fogAppend(den)
	}
	
	public static func ==(lhs: FogRational<T>, rhs: FogRational<T>) -> Bool {
		return lhs.num == rhs.num && lhs.den == rhs.den
	}
	
	public static func !=(lhs: FogRational<T>, rhs: FogRational<T>) -> Bool {
		return lhs.num != rhs.num || lhs.den != rhs.den
	}
}
