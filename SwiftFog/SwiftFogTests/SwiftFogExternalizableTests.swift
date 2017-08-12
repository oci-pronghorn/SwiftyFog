//
//  SwiftFogExternalizableTests.swift
//  SwiftFogTests
//
//  Created by David Giovannini on 8/12/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import XCTest
@testable import SwiftFog

struct BigDataBucket : FogExternalizable, Equatable {
	let uInt8: UInt8
	let sInt8: Int8
	let uInt16: UInt16
	let sInt16: Int16
	let uInt32: UInt32
	let sInt32: Int32
	let uInt64: UInt64
	let sInt64: Int64
	let utf8: String
	let byes: [UInt8]
	
	init() {
		self.uInt8 = UInt8.max - 5
		self.sInt8 = Int8.min + 7
		self.uInt16 = UInt16.max - 5
		self.sInt16 = Int16.min + 7
		self.uInt32 = UInt32.max - 5
		self.sInt32 = Int32.min + 7
		self.uInt64 = UInt64.max - 5
		self.sInt64 = Int64.min + 7
		self.utf8 = "Hello José"
		self.byes = [0x07, 0x09, 0x11]
	}
	
	static func ==(lhs: BigDataBucket, rhs: BigDataBucket) -> Bool {
		return
			lhs.uInt8 == rhs.uInt8 &&
			lhs.sInt8 == rhs.sInt8 &&
			lhs.uInt16 == rhs.uInt16 &&
			lhs.sInt16 == rhs.sInt16 &&
			lhs.uInt32 == rhs.uInt32 &&
			lhs.sInt32 == rhs.sInt32 &&
			lhs.uInt64 == rhs.uInt64 &&
			lhs.sInt64 == rhs.sInt64 &&
			lhs.utf8 == rhs.utf8 &&
			lhs.byes == rhs.byes
	}

	init(data: Data, cursor: inout Int) {
		self.uInt8 = data.fogExtract(&cursor)
		self.sInt8 = data.fogExtract(&cursor)
		self.uInt16 = data.fogExtract(&cursor)
		self.sInt16 = data.fogExtract(&cursor)
		self.uInt32 = data.fogExtract(&cursor)
		self.sInt32 = data.fogExtract(&cursor)
		self.uInt64 = data.fogExtract(&cursor)
		self.sInt64 = data.fogExtract(&cursor)
		self.utf8 = data.fogExtract(&cursor) ?? "Bad"
		self.byes = data.fogExtract(len: 3, &cursor)
	}
	
	func writeTo(data: inout Data) {
		data.fogAppend(self.uInt8)
		data.fogAppend(self.sInt8)
		data.fogAppend(self.uInt16)
		data.fogAppend(self.sInt16)
		data.fogAppend(self.uInt32)
		data.fogAppend(self.sInt32)
		data.fogAppend(self.uInt64)
		data.fogAppend(self.sInt64)
		data.fogAppend(self.utf8)
		data.fogAppend(self.byes)
	}
}

class SwiftFogExternalizableTests: XCTestCase {
    
    func testBigDataBucket() {
		let src = BigDataBucket()
		var stream = Data()
		src.writeTo(data: &stream)
		let written = stream.count
		var read = 0
		let dest = BigDataBucket(data: stream, cursor: &read)
		
		XCTAssertTrue(written == read)
		XCTAssertTrue(src == dest)
    }
    
    func testFogBitmapLayout() {
		var src = FogBitmapLayout(colorSpace: .rgba)
		src.width = 23
		src.height = 65
		src.componentDepth = 6
		src.minComponentWidth = 2
		
		var stream = Data()
		src.writeTo(data: &stream)
		let written = stream.count
		var read = 0
		let dest = FogBitmapLayout(data: stream, cursor: &read)
		
		XCTAssertTrue(written == read)
		XCTAssertTrue(src == dest)
    }
    
}
