//
//  FogBitMap.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/8/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

#if os(iOS)
import UIKit
#else
import Cocoa
#endif

public struct FogBitMap: FogExternalizable, CustomStringConvertible {
	public let layout: FogBitmapLayout
	private var bmp: [UInt8]
	
	public init(layout: FogBitmapLayout) {
		self.layout = layout
		self.bmp = [UInt8](repeating: 0, count: layout.bmpSize)
	}
	
	public init?(data: Data, cursor: inout Int) {
		guard let layout: FogBitmapLayout = data.fogExtract(&cursor) else { return nil }
		self.layout = layout
		self.bmp = data.fogExtract(len: layout.bmpSize, &cursor)
	}
	
	public var fogSize: Int {
		return layout.fogSize + bmp.count
	}
	
	public func writeTo(data: inout Data) {
		data.fogAppend(layout)
		data.fogAppend(bmp)
	}
	
	public var description: String {
		var str = layout.description + "\n"
		for x in 0..<layout.width {
			for y in 0..<layout.width {
				for z in 0..<layout.componentWidth {
					let address = layout.address(x: Int(x), y: Int(y), z: Int(z))
					let c = layout.component(bmp: bmp, i: address)
					str += "\(c) \(z==layout.componentWidth-1 ? " " : ".")"
				}
			}
			str += "\n"
		}
		return str
	}
#if os(iOS)
	public mutating func imbue(_ source: UIImage) -> UIImage? {
		let corrected = source.fogFixedOrientation()
		let resized = corrected.fogResize(layout.size)
		if let toScan = resized {
			toScan.fogScanPixels(scan: { (x, y, p) -> Bool in
				let dest = toScan.fogColorSpace.convert(pixel: p, to: self.layout.colorSpace)
				self.layout.setPixel(bmp: &bmp, x: x, y: y, pixel: dest)
				return true
			})
		}
		return resized
	}
	
	public var image: UIImage? {
        return nil
    }
#endif
}
