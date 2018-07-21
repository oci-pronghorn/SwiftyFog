//
//  ScrewsView.swift
//  TrainControl
//
//  Created by David Giovannini on 7/21/18.
//  Copyright © 2018 Object Computing Inc. All rights reserved.
//

import UIKit

@IBDesignable
class ScrewsView: UIView {
	
	@IBInspectable public var screwImage: UIImage? {
		didSet {
			self.setNeedsDisplay()
		}
	}
	
	@IBInspectable public var screwRadius: CGFloat = 10.0 {
		didSet {
			self.setNeedsDisplay()
		}
	}
	
	@IBInspectable public var inset: CGFloat = 15.0 {
		didSet {
			self.setNeedsDisplay()
		}
	}
	
	override func draw(_ rect: CGRect) {
		if let screwImage = screwImage {
			let s = self.bounds.size
			let r1 = CGRect(
				x: inset - screwRadius,
				y: (s.height / 2.0) - screwRadius,
				width: screwRadius * 2.0,
				height: screwRadius * 2.0)
			
			screwImage.draw(in: r1)
			
			let r2 = CGRect(
				x: s.width - (inset + screwRadius),
				y: (s.height / 2.0) - screwRadius,
				width: screwRadius * 2.0,
				height: screwRadius * 2.0)
			screwImage.draw(in: r2)
		}
	}
}
