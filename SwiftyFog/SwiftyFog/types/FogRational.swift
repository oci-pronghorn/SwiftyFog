//
//  FogRational.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/9/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation
/*
public extension BinaryInteger {
	public init?(fogPackedData data: Data) {
		var cursor = 0
		self.init(fogPackedData: data, &cursor)
	}
	
	public init?(fogPackedData data: Data, _ cursor: inout Int) {
		let maxBits = MemoryLayout<Self>.size * 8
		var temp: Self = 0
		let success: Bool = data.withUnsafeBytes { (u8Ptr: UnsafePointer<UInt8>) in
			var i = 0
			repeat {
				let byte = u8Ptr[cursor + i]
				temp |= Self(byte & 0x7F)
				i += 1
				if (byte & 0x80) != 0 {
					cursor += i
					return true
				}
				temp <<= 7
			} while (i * 7) <= maxBits
			return false
		}
		if success == false {
			return nil
		}
		self = temp
	}
	
	public func writeUnsigned(fogPackedData data: inout Data) {
	}
	
	public func writeSigned(fogPackedData: inout Data) {
	}
}

public extension BinaryInteger where Self: UnsignedInteger {
	public func write(fogPackedData data: inout Data) {
		self.writeUnsigned(fogPackedData: &data)
	}
}

public extension BinaryInteger where Self: SignedInteger {
	public func write(fogPackedData data: inout Data) {
		if self < 0 {
			self.writeSigned(fogPackedData: &data)
		}
		else {
			self.writeUnsigned(fogPackedData: &data)
		}
	}
}
*/
public struct FogRational<T: FixedWidthInteger> : Equatable, FogExternalizable, CustomStringConvertible {
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
