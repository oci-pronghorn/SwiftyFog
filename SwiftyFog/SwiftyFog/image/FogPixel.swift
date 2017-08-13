//
//  FogPixel.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/8/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import UIKit

public protocol PixelKind: Equatable {
	init(pixel: [CGFloat])
	var pixel: [CGFloat] { get }
}

extension PixelKind {
	public static func ==(lhs: Self, rhs: Self) -> Bool {
		return lhs.pixel == rhs.pixel
	}
}

extension FogColorSpace {
	public func convert(pixel: [CGFloat], to: FogColorSpace) -> [CGFloat] {
		switch self {
			case .gray:
				let s = Gray(pixel: pixel)
				switch to {
					case .gray:
						return pixel
					case .rgb:
						return RGB(gray: s).pixel
					case .rgba:
						return RGB(gray: s).pixel
				}
			case .rgb:
				let s = RGB(pixel: pixel)
				switch to {
					case .gray:
						return Gray(rgb: s).pixel
					case .rgb:
						return pixel
					case .rgba:
						return pixel
				}
			case .rgba:
				let s = RGB(pixel: pixel)
				switch to {
					case .gray:
						return Gray(rgb: s).pixel
					case .rgb:
						return pixel
					case .rgba:
						return pixel
				}
		}
	}
}

public struct Gray: PixelKind {
	
	public let pixel: [CGFloat]
	
    var l: CGFloat { return pixel[0] }
    var a: CGFloat { return pixel[1] }
	
    public init(pixel: [CGFloat]) {
		self.pixel = pixel
    }
	
	init(l: CGFloat, a: CGFloat = 1.0) {
		self.pixel = [l, a]
	}
	
    init(rgb: RGB) {
		let l = (rgb.r + rgb.g + rgb.b) / 3.0
		let a = rgb.a
		self.pixel = [l, a]
    }
}

public struct RGB: PixelKind {
	public let pixel: [CGFloat]
	
    var r: CGFloat { return pixel[0] }
    var g: CGFloat { return pixel[1] }
    var b: CGFloat { return pixel[2] }
    var a: CGFloat { return pixel[3] }
	
    public init(pixel: [CGFloat]) {
		self.pixel = pixel
    }
	
	init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1.0) {
		self.pixel = [r, g, b, a]
	}
	
    init(gray: Gray) {
		self.pixel = [gray.l, gray.l, gray.l, gray.a]
    }
	
	init(hvs: HSV) {
		let h = hvs.h
		let s = hvs.s
		let v = hvs.v
		let a = hvs.a
	
        if s == 0 {
			self.init(r: v, g: v, b: v, a: a)
			return
		} // Achromatic gray
		
        let angle = (h >= 360 ? 0 : h) // todo make [0,1] of 2π
        let sector = angle / 60 // Sector
        let i = floor(sector)
        let f = sector - i // Factorial part of h
		
        let p = v * (1 - s)
        let q = v * (1 - (s * f))
        let t = v * (1 - (s * (1 - f)))
		
        switch(i) {
        case 0:
            self.init(r: v, g: t, b: p, a: a)
            break
        case 1:
            self.init(r: q, g: v, b: p, a: a)
            break
        case 2:
            self.init(r: p, g: v, b: t, a: a)
            break
        case 3:
            self.init(r: p, g: q, b: v, a: a)
            break
        case 4:
            self.init(r: t, g: p, b: v, a: a)
            break
        default:
            self.init(r: v, g: p, b: q, a: a)
            break
        }
    }
}

public struct HSV: PixelKind {
    let h: CGFloat // Angle in degrees [0,360] or -1 as Undefined
    let s: CGFloat // [0,1]
    let v: CGFloat // [0,1]
    let a: CGFloat // [0,1]
	
    public var pixel: [CGFloat] {
		return [h, s, v, a]
    }
	
    public init(pixel: [CGFloat]) {
		h = pixel[0]
		s = pixel[1]
		v = pixel[2]
		a = pixel.last ?? 1.0
    }
	
	init(h: CGFloat, s: CGFloat, v: CGFloat, a: CGFloat = 1.0) {
		self.h = h
		self.s = s
		self.v = v
		self.a = a
	}
	
    init(gray: Gray) {
		self.h = 0.0
		self.s = 0.0
		self.v = gray.l
		self.a = gray.a
    }
	
    init(rgb: RGB) {
		let r = rgb.r
		let g = rgb.g
		let b = rgb.b
		let a = rgb.a
		
        let min = r < g ? (r < b ? r : b) : (g < b ? g : b)
        let max = r > g ? (r > b ? r : b) : (g > b ? g : b)
		
        let v = max
        let delta = max - min
		
        guard delta > 0.00001 else {
			self.init(h: 0, s: 0, v: max, a: a)
			return
		}
        guard max > 0 else {
			self.init(h: -1, s: 0, v: v, a: a)
			return
		} // Undefined, achromatic gray
        let s = delta / max
		
        let hue: (CGFloat, CGFloat) -> CGFloat = { max, delta -> CGFloat in
            if r == max { return (g-b)/delta } // between yellow & magenta
            else if g == max { return 2 + (b-r)/delta } // between cyan & yellow
            else { return 4 + (r-g)/delta } // between magenta & cyan
        }
		
        let h = hue(max, delta) * 60 // In degrees todo make [0,1] of 2π
		
        self.init(h: (h < 0 ? h+360 : h) , s: s, v: v, a: a)
    }
}
