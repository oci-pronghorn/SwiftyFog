//
//  fogSize.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/22/17.
//

public extension FixedWidthInteger {
	public var fogSize: Int {
		return MemoryLayout<Self>.size
	}
	
	public static var fogSize: Int {
		return MemoryLayout<Self>.size
	}
}

public extension Bool {
	public var fogSize: Int {
		return UInt8.fogSize
	}
	
	public static var fogSize: Int {
		return UInt8.fogSize
	}
}

extension String.UTF8View {
	var fogSize: Int {
		return UInt16.fogSize + self.count
	}
}

extension Optional where Wrapped == String.UTF8View {
	var fogSize: Int {
		return UInt16.fogSize + (self?.count ?? 0)
	}
}

public extension RawRepresentable where RawValue: FixedWidthInteger {
	public var fogSize: Int {
		return RawValue.fogSize
	}
	
	public static var fogSize: Int {
		return RawValue.fogSize
	}
}
