//
//  Billboard.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/9/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
public  class ScrubControl : UIControl {

	fileprivate var scrubTap: UITapGestureRecognizer!
	fileprivate var scrubPan: UIPanGestureRecognizer!
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		self.setupRecognizers()
	}
	
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		self.setupRecognizers()
	}

	override public func layoutSubviews() {
		super.layoutSubviews()
		self.setNeedsDisplay()
	}
	
	@IBInspectable
	public var normValue: Float = 0.5 {
		didSet {
			self.setNeedsDisplay()
		}
	}

	public var value: Float {
		set {
			normValue = (newValue - minimumValue) / (maximumValue - minimumValue)
		}
		get {
			return minimumValue + ((maximumValue - minimumValue) * normValue)
		}
	}
	
	@IBInspectable
	public var minimumValue: Float = 0.0 {
		didSet {
			self.setNeedsDisplay()
		}
	}
	
	@IBInspectable
	public var maximumValue: Float = 1.0 {
		didSet {
			self.setNeedsDisplay()
		}
	}
	
	@IBInspectable
	public var velocityAdjustWidthFactor: CGFloat = 20 {
		didSet {
			self.setNeedsDisplay()
		}
	}

	@IBInspectable
	public var scrubHeight: CGFloat = 32 {
		didSet {
			self.setNeedsDisplay()
		}
	}
	
	@IBInspectable var cursorColor: UIColor = UIColor.blue {
		didSet {
			self.setNeedsDisplay()
		}
	}
	
	@IBInspectable var tickColor: UIColor = UIColor.black.withAlphaComponent(0.5) {
		didSet {
			self.setNeedsDisplay()
		}
	}
	
	@IBInspectable var tickBackground: UIColor = UIColor.black.withAlphaComponent(0.15) {
		didSet {
			self.setNeedsDisplay()
		}
	}
	
	@IBInspectable var tickThickness: CGFloat = 1.0 {
		didSet {
			self.setNeedsDisplay()
		}
	}
	
	@IBInspectable var cursorThickness: CGFloat = 2.0 {
		didSet {
			self.setNeedsDisplay()
		}
	}
	
	@IBInspectable var density: Int = 20 {
		didSet {
			self.setNeedsDisplay()
		}
	}
	
	override public func draw(_ rect: CGRect) {
		let context = UIGraphicsGetCurrentContext()!
		let value = CGFloat(self.normValue)
		
		if density > 0 {
			

			let t: CGFloat = bounds.origin.y
			let l: CGFloat = bounds.origin.x
			let h: CGFloat = scrubHeight
			let w: CGFloat = bounds.size.width
			let b = t + h

			context.setFillColor(tickBackground.cgColor)
			context.fill(CGRect(x: l, y: t, width: w, height: h))
			
			let w0 = w * value
			let w1 = w * (1.0 - value)
		
			context.setLineWidth(tickThickness)
			context.setStrokeColor(tickColor.cgColor)
		
			let count2 = CGFloat(density) * CGFloat(density)
			
			for i in 0..<density {
				let time = CGFloat(i + 1)
				let position = time * time / count2
				
				let round = (1.0 - position) * (h * 1.0/3.0)
				
				let x0 = w0 - (position * w0)
				let t0 = CGPoint(x: l + x0, y: t + round)
				let b0 = CGPoint(x: l + x0, y: b - round)
				context.move(to: t0)
				context.addLine(to: b0)
				
				let x1 = w0 + (position * w1)
				let t1 = CGPoint(x: l + x1, y: t + round)
				let b1 = CGPoint(x: l + x1, y: b - round)
				context.move(to: t1)
				context.addLine(to: b1)
			}
			context.strokePath()
		}

		context.setLineWidth(cursorThickness)
		context.setStrokeColor(cursorColor.cgColor)
		
		let scaleX = self.bounds.width
		let scaleY = (self.bounds.height - scrubHeight)
		let v = value * scaleX
		context.move(to: CGPoint(x: v, y: 0.0))
		context.addLine(to: CGPoint(x: v, y: scaleY + scrubHeight))
		context.strokePath()
	}
}

extension ScrubControl: UIGestureRecognizerDelegate {
	
	fileprivate func setupRecognizers() {
		scrubTap = UITapGestureRecognizer(target: self, action: #selector(scrubTapped))
		self.addGestureRecognizer(scrubTap)
		
		scrubPan = UIPanGestureRecognizer(target: self, action: #selector(scrubPanned))
		self.addGestureRecognizer(scrubPan)
	}
	
	override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
		let hit = super.hitTest(point, with: event);
		return hit != nil && point.y <= scrubHeight ? hit : nil
	}
	
	@objc private func scrubTapped(_ gestureRecognizer: UITapGestureRecognizer) {
		let viewPoint = gestureRecognizer.location(in: self)
		let scaleX = viewPoint.x / self.bounds.width
		let x = min(max(scaleX, 0.0), 1.0)
		self.normValue = Float(x)
		self.sendActions(for: .valueChanged)
	}
	
	@objc private func scrubPanned(_ gestureRecognizer: UIPanGestureRecognizer) {
		let vp = gestureRecognizer.velocity(in: self)
		let v = vp.x
		let d = Float(v / (self.velocityAdjustWidthFactor * self.bounds.width))
		let start = self.normValue
		let m = start + d
		self.normValue = min(max(m, 0.0), 1.0)
		self.sendActions(for: .valueChanged)
	}
}

