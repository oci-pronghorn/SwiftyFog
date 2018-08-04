//
//  SimplePopoverbackground.swift
//  SBJCommon
//
//  Created by David Giovannini on 1/23/17.
//  Copyright © 2017 Software by Jove. All rights reserved.
//

import UIKit

public class SimplePopoverbackground: UIPopoverBackgroundView {

	public static func assign(popover: UIPopoverPresentationController?) {
		guard let popover = popover else { return }
		popover.popoverBackgroundViewClass = SimplePopoverbackground.self
		popover.backgroundColor = UIColor.clear
		// As of iOS, non-toolbar anchor views will anchor top-left!
		guard #available(iOS 9.0, *) else { return }
		if let anchor = popover.sourceView, popover.sourceRect == CGRect() {
			popover.sourceRect = anchor.bounds
		}

	}

	override init(frame: CGRect) {
		super.init(frame: frame)
		self.isOpaque = false
		self.backgroundColor = UIColor.clear
		self.layer.shadowColor = UIColor.clear.cgColor
		self.tintColor = UIColor.brown
	}
	
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		self.isOpaque = false
		self.backgroundColor = UIColor.clear
		self.layer.shadowColor = UIColor.clear.cgColor
		self.tintColor = UIColor.brown
	}
	
	private static let arrowWidth: CGFloat = 6.0

    public override static func arrowBase() -> CGFloat { return 0.0 }
    public override static func arrowHeight() -> CGFloat { return 0.0 }

    public override static func contentViewInsets() -> UIEdgeInsets {
		return UIEdgeInsets(top: arrowWidth + 2, left: arrowWidth + 2, bottom: arrowWidth + 2, right: arrowWidth + 2)
	}
	
	private var _arrowOffset: CGFloat = 0.0
	open override var arrowOffset: CGFloat {
		set {
			_arrowOffset = newValue
			self.setNeedsDisplay()
		}
		get {
			return _arrowOffset
		}
	}
	
	private var _arrowDirection: UIPopoverArrowDirection = UIPopoverArrowDirection(rawValue: 0)
	open override var arrowDirection: UIPopoverArrowDirection {
		set {
			_arrowDirection = newValue
			self.setNeedsDisplay()
		}
		get {
			return _arrowDirection
		}
	}
	
    open override class var wantsDefaultContentAppearance: Bool { return false }
	
	override public func draw(_ rect: CGRect) {
		let ctx = UIGraphicsGetCurrentContext()!
		ctx.saveGState()
		let aw = SimplePopoverbackground.arrowWidth
		let ah = aw / 2.0
		let asize = CGSize(width: aw, height: aw)
		let b = self.bounds
		let r = b.insetBy(dx: ah, dy: ah)
		let path = UIBezierPath(roundedRect: r, cornerRadius: 18)

		ctx.setFillColor(UIColor.black.withAlphaComponent(0.1).cgColor)
		path.fill()
		ctx.setFillColor(self.tintColor.cgColor)
		if _arrowDirection == .up {
			let offset = max(b.minX, min(b.midX+_arrowOffset-ah, b.maxX-ah))
			ctx.fillEllipse(in: CGRect(origin: CGPoint(x: offset, y: b.minY), size: asize))
		}
		else if _arrowDirection == .down {
			let offset = max(b.minX, min(b.midX+_arrowOffset-ah, b.maxX-ah))
			ctx.fillEllipse(in: CGRect(origin: CGPoint(x: offset, y: b.maxY-aw), size: asize))
		}
		else if _arrowDirection == .left {
			let offset = max(b.minY, min(b.midY+_arrowOffset-ah, b.maxY-ah))
			ctx.fillEllipse(in: CGRect(origin: CGPoint(x: b.minX, y: offset), size: asize))
		}
		else if _arrowDirection == .right {
			let offset = max(b.minY, min(b.midY+_arrowOffset-ah, b.maxY-ah))
			ctx.fillEllipse(in: CGRect(origin: CGPoint(x: b.maxX-aw, y: offset), size: asize))
		}
		ctx.restoreGState()
	}
}
