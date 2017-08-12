//
//  FogBitMap.swift
//  TrainControl
//
//  Created by David Giovannini on 8/8/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import UIKit

public struct FogBitMap: FogExternalizable {
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
}
