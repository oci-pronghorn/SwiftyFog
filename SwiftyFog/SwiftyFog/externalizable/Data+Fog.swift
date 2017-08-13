//
//  Data+Fog.swift
//  SwiftyFog
//
//  Created by David Giovannini on 7/29/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

public extension Data {
	public mutating func fogAppend(_ value: [UInt8]) {
		self.append(contentsOf: value)
	}
	
	public mutating func fogAppend(_ value: String) {
		let view = value.utf8
		self.fogAppend(UInt16(view.count))
		self.append(contentsOf: view)
	}
	
	public mutating func fogAppend <T: FixedWidthInteger> (_ rhs: T) {
		var value = rhs.bigEndian
		self.append(UnsafeBufferPointer(start: &value, count: 1))
	}
	
	public mutating func fogAppend<T: FogExternalizable>(_ rhs: T) {
		rhs.writeTo(data: &self)
	}

	public func fogExtract(len: Int, _ cursor: inout Int) -> [UInt8] {
		let subData = self.subdata(in: cursor..<(cursor+len))
		cursor += len
		return Array(subData)
	}
	
	public func fogExtract() -> [UInt8] {
		var cursor = 0
		return fogExtractRaw(&cursor)
	}
	
	public func fogExtract <T: FixedWidthInteger> (_ cursor: inout Int) -> T {
		return T(bigEndian: fogExtractRaw(&cursor));
	}
	
	public func fogExtract(_ cursor: inout Int) -> String? {
		let len: UInt16 = fogExtract(&cursor)
		let subData = self.subdata(in: cursor..<(cursor+Int(len)))
		cursor += Int(len)
		return String(data: subData, encoding: .utf8)
	}
	
	public func fogExtract <T: FixedWidthInteger> () -> T {
		var cursor = 0
		return T(bigEndian: fogExtractRaw(&cursor));
	}
	
	public func fogExtract<T: FogExternalizable>(_ cursor: inout Int) -> T {
		return T(data: self, cursor: &cursor)
	}
	
	public func fogExtract<T: FogExternalizable>() -> T {
		var cursor = 0
		return T(data: self, cursor: &cursor)
	}
	
	private func fogExtractRaw <T> (_ cursor: inout Int) -> T {
		return self.withUnsafeBytes { (u8Ptr: UnsafePointer<UInt8>) in
			let pos = u8Ptr.advanced(by: cursor)
			return pos.withMemoryRebound(to: T.self, capacity: 1) { (c) -> T in
				cursor += MemoryLayout<T>.size
				return c.pointee
			}
		}
	}
}
