//
//  FogBitmapLayout.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/8/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import UIKit

public struct FogBitmapLayout: FogExternalizable, Equatable {
    public var width: UInt32 = 1
    public var height: UInt32 = 1
    public var colorSpace: FogColorSpace = .gray
    public var componentDepth: UInt8 = 8
    public var minComponentWidth: UInt8 = 1
	
    public var componentWidth: UInt32 { return max(UInt32((CGFloat(componentDepth) / 8.0).rounded(.up)), UInt32(minComponentWidth)) }
    
    public var magnitude: CGFloat { return pow(CGFloat(componentDepth), 2.0) }
	
    public var size: CGSize { return CGSize(width: CGFloat(width), height: CGFloat(height)) }
	
    public init(colorSpace: FogColorSpace = .gray) {
		self.colorSpace = colorSpace
    }
	
	public init(data: Data, cursor: inout Int) {
		width = data.fogExtract(&cursor)
		height = data.fogExtract(&cursor)
		colorSpace = data.fogExtract(&cursor)
		componentDepth = data.fogExtract(&cursor)
		minComponentWidth = data.fogExtract(&cursor)
	}
	
	public func writeTo(data: inout Data) {
		data.fogAppend(width)
		data.fogAppend(height)
		data.fogAppend(colorSpace)
		data.fogAppend(componentDepth)
		data.fogAppend(minComponentWidth)
	}
	
	var fogSize: Int {
		return
			MemoryLayout.size(ofValue: width) +
			MemoryLayout.size(ofValue: height) +
			MemoryLayout.size(ofValue: colorSpace.rawValue) +
			MemoryLayout.size(ofValue: componentDepth) +
			MemoryLayout.size(ofValue: minComponentWidth)
	}
	
	public static func ==(lhs: FogBitmapLayout, rhs: FogBitmapLayout) -> Bool {
		return
			lhs.width == lhs.width &&
			lhs.height == lhs.height &&
			lhs.colorSpace == lhs.colorSpace &&
			lhs.componentDepth == lhs.componentDepth &&
			lhs.minComponentWidth == lhs.minComponentWidth
	}
	
    public var bmpSize: Int {
		return Int(width * height * colorSpace.componentCount * componentWidth)
    }
	
    public func address(_ x: Int, y: Int, z: Int) -> Int {
		let pixel: Int = Int(colorSpace.componentCount) * Int(componentWidth)
		let row: Int = Int(width) * pixel
		return Int((x * row) + (y * pixel))
    }
	
    public func pixel(bmp: [UInt8], x: Int, y: Int) -> [CGFloat] {
		var pixel = [CGFloat]()
		pixel.reserveCapacity(Int(colorSpace.componentCount))
		for z in 0..<Int(colorSpace.componentCount) {
			let i = address(x, y: y, z: z)
			let v = value(bmp: bmp, i: i)
			pixel.append(v)
		}
		return pixel
    }
	
    public func setPixel(bmp: inout [UInt8], x: Int, y: Int, pixel: [CGFloat]) {
		for z in 0..<Int(colorSpace.componentCount) {
			let i = address(x, y: y, z: z)
			setValue(bmp: &bmp, i: i, value: pixel[z])
		}
	}
	
    public func value(bmp: [UInt8], i: Int) -> CGFloat {
		let component = CGFloat(self.component(bmp: bmp, i: i))
		let magnitude = pow(CGFloat(componentDepth), 2.0)
		return component / magnitude
    }
	
    public func setValue(bmp: inout [UInt8], i: Int, value: CGFloat) {
		let magnitude = pow(CGFloat(componentDepth), 2.0)
		let component = UInt32(value * magnitude)
		setComponent(bmp: &bmp, i: i, component: component)
    }
	
    public func component(bmp: [UInt8], i: Int) -> UInt32 {
		switch (componentWidth) {
			case 1:
				let v1 = UInt32(bmp[i+0])
				let v = v1
				return v
			case 2:
				let v1 = UInt32(bmp[i+0])
				let v2 = UInt32(bmp[i+1])
				let v: UInt32 = (v1 << 8) | v2
				return v
			case 3:
				let v1 = UInt32(bmp[i+0])
				let v2 = UInt32(bmp[i+1])
				let v3 = UInt32(bmp[i+2])
				let v: UInt32 = (v1 << 16) | (v2 << 8) | v3
				return v
			case 4:
				let v1 = UInt32(bmp[i+0])
				let v2 = UInt32(bmp[i+1])
				let v3 = UInt32(bmp[i+2])
				let v4 = UInt32(bmp[i+3])
				let v: UInt32 = (v1 << 24) | (v2 << 16) | (v3 << 8) | v4
				return v
			default:
				return 0
		}
    }
	
    public func setComponent(bmp: inout [UInt8], i: Int, component: UInt32) {
		switch (componentWidth) {
			case 1:
				bmp[i+0] = UInt8(component)
				break
			case 2:
				bmp[i+0] = UInt8(component & 0x0000000F)
				bmp[i+1] = UInt8(component & 0x000000F0 >> 8)
				break
			case 3:
				bmp[i+0] = UInt8(component & 0x0000000F)
				bmp[i+1] = UInt8(component & 0x000000F0 >> 8)
				break
			case 4:
				break
			default:
				break
		}
    }
}
