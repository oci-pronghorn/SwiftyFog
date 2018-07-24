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
	
	@IBInspectable public var screwCount: Int = 2 {
		didSet {
			self.setNeedsDisplay()
		}
	}
	
	override func draw(_ rect: CGRect) {
		if let screwImage = screwImage {
			let s = self.bounds.size
			var points: [CGPoint] = []
			switch screwCount {
				case 1:
					points = [
						CGPoint(
							x: s.width / 2.0 - screwRadius,
							y: inset - screwRadius)
					]
				case 2:
					points = [
						CGPoint(
							x: inset - screwRadius,
							y: (s.height / 2.0) - screwRadius),
						CGPoint(
							x: s.width - (inset + screwRadius),
							y: (s.height / 2.0) - screwRadius),
					]
				case 3:
					points = [
						CGPoint(
							x: s.width / 2.0 - screwRadius,
							y: inset - screwRadius),
						CGPoint(
							x: inset - screwRadius,
							y: s.height - (inset + screwRadius)),
						CGPoint(
							x: s.width - (inset + screwRadius),
							y: s.height - (inset + screwRadius)),
					]
				case 4:
					points = [
						CGPoint(
							x: inset - screwRadius,
							y: inset - screwRadius),
						CGPoint(
							x: s.width - (inset + screwRadius),
							y: inset - screwRadius),
						CGPoint(
							x: s.width - (inset + screwRadius),
							y: s.height - (inset + screwRadius)),
						CGPoint(
							x: inset - screwRadius,
							y: s.height - (inset + screwRadius)),
					]
				default:
					break
			}
			points.forEach {
				screwImage.draw(in: CGRect(x: $0.x, y: $0.y, width: screwRadius * 2.0, height: screwRadius * 2.0))
			}
		}
	}
}
