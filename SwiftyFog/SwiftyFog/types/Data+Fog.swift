//
//  Data+Fog.swift
//  SwiftyFog
//
//  Created by David Giovannini on 7/29/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation // Data

internal extension Date {
	static func nowInSeconds() -> Int64 {
		return Int64(Date().timeIntervalSince1970.rounded())
	}
}

public extension Data {
    public var fogHexDescription: String {
		if self.count == 0 {
			return ""
		}
        return "\n\(fogHexFormat(bytesPerRow: 16, indent: "\t"))"
    }
	
    public func fogHexFormat(bytesPerRow: Int = Int.max, indent: String = "") -> String {
		if self.count == 0 {
			return ""
		}
		var desc = reduce(("", 1)) { a, e in
			var iter = a
			let i = (iter.1-1) % bytesPerRow == 0 ? indent : ""
			let val = String(format: "%02x", e)
			let term = iter.1 % bytesPerRow == 0 ? "\n" : iter.1 % 2  == 0 ? " " :  "."
			iter.0 = iter.0 + "\(i)\(val)\(term)"
			iter.1 += 1
			return iter
		}
		desc.0.removeLast()
		return desc.0
    }
}

public extension Data {
	private func fogExtractRaw<T>(_ cursor: inout Int) -> T {
		return self.withUnsafeBytes { (u8Ptr: UnsafePointer<UInt8>) in
			let pos = u8Ptr.advanced(by: cursor)
			return pos.withMemoryRebound(to: T.self, capacity: 1) { (c) -> T in
				cursor += MemoryLayout<T>.size
				return c.pointee
			}
		}
	}
}

public extension Data {
	public mutating func fogAppend(_ value: String) {
		self.fogAppend(value.utf8)
	}
	
	public mutating func fogAppend(_ value: String.UTF8View) {
		self.fogAppend(UInt16(value.count))
		self.append(contentsOf: value)
	}
	
    public mutating func fogAppend<T: RawRepresentable>(_ value: T) where T.RawValue == String {
		self.fogAppend(value.rawValue)
    }
	
	public func fogExtract() -> String? {
		var cursor = 0
		return fogExtract(&cursor)
	}
	
	public func fogExtract(_ cursor: inout Int) -> String? {
		let len: UInt16 = fogExtract(&cursor)
		let subData = self.subdata(in: cursor..<(cursor+Int(len)))
		cursor += Int(len)
		return String(data: subData, encoding: .utf8)
	}
	
	public func fogExtract<T: RawRepresentable>() -> T? where T.RawValue == String {
		var cursor = 0
		return fogExtract(&cursor)
	}
	
	public func fogExtract<T: RawRepresentable>(_ cursor: inout Int) -> T? where T.RawValue == String {
		if let str: String = fogExtract(&cursor) {
			return T(rawValue: str)
		}
		return nil
	}
}

public extension Data {
	public mutating func fogAppend(_ value: [UInt8]) {
		self.append(contentsOf: value)
	}
	
	public func fogExtract() -> [UInt8] {
		var cursor = 0
		return fogExtractRaw(&cursor)
	}

	public func fogExtract(len: Int, _ cursor: inout Int) -> [UInt8] {
		let subData = self.subdata(in: cursor..<(cursor+len))
		cursor += len
		return Array(subData)
	}
}


public extension Data {
	public mutating func fogAppend(_ rhs: Bool) {
		fogAppend(UInt8(rhs ? 1 : 0))
	}
	
	public func fogExtract(_ cursor: inout Int) -> Bool {
		return (fogExtract(&cursor) as UInt8) == 0 ? false : true
	}
	
	public func fogExtract() -> Bool {
		var cursor = 0
		return fogExtract(&cursor)
	}
}

public extension Data {
	public mutating func fogAppend<T: FixedWidthInteger>(_ rhs: T) {
		var value = rhs.bigEndian
		self.append(UnsafeBufferPointer(start: &value, count: 1))
	}
	
    public mutating func fogAppend<T: RawRepresentable>(_ value: T) where T.RawValue: FixedWidthInteger {
		self.fogAppend(value.rawValue)
    }
	
	public func fogExtract<T: FixedWidthInteger>() -> T {
		var cursor = 0
		return fogExtract(&cursor)
	}
	
	public func fogExtract<T: FixedWidthInteger>(_ cursor: inout Int) -> T {
		return T(bigEndian: fogExtractRaw(&cursor));
	}
	
	public func fogExtract<T: RawRepresentable>() -> T? where T.RawValue: FixedWidthInteger {
		var cursor = 0
		return fogExtract(&cursor)
	}
	
	public func fogExtract<T: RawRepresentable>(_ cursor: inout Int) -> T? where T.RawValue: FixedWidthInteger {
		return T(rawValue: fogExtract(&cursor))
	}
}

public extension Data {
	public mutating func fogAppend<T: FogWritingExternalizable>(_ rhs: T) {
		rhs.writeTo(data: &self)
	}
	
	public func fogExtract<T: FogReadingExternalizable>() -> T? {
		var cursor = 0
		return T(data: self, cursor: &cursor)
	}
	
	public func fogExtract<T: FogReadingExternalizable>(_ cursor: inout Int) -> T? {
		return T(data: self, cursor: &cursor)
	}
}
