//
//  FogBitMap.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/8/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import UIKit

public struct FogBitMap: FogExternalizable, CustomStringConvertible {
	private let layout: FogBitmapLayout
	private var bmp: [UInt8]
	
	public init(layout: FogBitmapLayout) {
		self.layout = layout
		bmp = [UInt8](repeating: 0, count: layout.bmpSize)
	}
	
	public init(data: Data, cursor: inout Int) {
		layout = data.fogExtract(&cursor)
		bmp = data.fogExtract(len: layout.bmpSize, &cursor)
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
	
	public mutating func imbue(image: UIImage) {
		let resized  = image.fogResize(size: CGSize(width: CGFloat(layout.width), height: CGFloat(layout.height)))
		if let img = resized {
			img.fogScanPixels(scan: { (x, y, p) -> Bool in
				let dest = img.fogColorSpace.convert(pixel: p, to: self.layout.colorSpace)
				self.layout.setPixel(bmp: &bmp, x: x, y: y, pixel: dest)
				return true
			})
		}
	}
	
	public var image: UIImage? {
        return nil
    }
}
