//
//  GaugeView.swift
//  TrainControl
//
//  Created by David Giovannini on 7/10/18.
//  Based on WMGaugeView by William Markezana <william.markezana@me.com>
//  Copyright © 2018 Software by Jove. All rights reserved.
//

import UIKit

// TODO: use polymorphism for element drawing
// TODO: isolate hard-coded colors and dimensions to those elements

enum GaugeViewSubdivisionsAlignment : String {
    case top
    case center
    case bottom
}

enum GaugeViewNeedleStyle : String {
	case none
    case threeD
    case flatThin
}

enum GaugeViewNeedleScrewStyle : String {
	case none
    case gradient
    case plain
}

enum GaugeViewInnerBackgroundStyle : String {
	case none
    case gradient
    case flat
}

fileprivate extension UIColor {
	fileprivate convenience init(_ r: Int, _ g: Int, _ b: Int) {
		self.init(red: CGFloat(r)/255.0, green: CGFloat(g)/255.0, blue: CGFloat(b)/255.0, alpha: 1.0)
	}
	fileprivate convenience init(_ r: Int, _ g: Int, _ b: Int, _ a: Int) {
		self.init(red: CGFloat(r)/255.0, green: CGFloat(g)/255.0, blue: CGFloat(b)/255.0, alpha: CGFloat(a)/255.0)
	}
}

fileprivate extension CGContext {
	fileprivate func rotate(fromCenter center_: CGPoint, withAngle angle: CGFloat) {
		self.translateBy(x: center_.x, y: center_.y)
		self.rotate(by: angle)
		self.translateBy(x: -center_.x, y: -center_.y)
	}
}

fileprivate extension CGFloat {
	fileprivate var degToRad: CGFloat {
		return (.pi * self) / 180
	}
}

@IBDesignable
class GaugeRange: NSObject {
    @IBInspectable public var value: CGFloat = 0.0 { didSet { owner?.rangesChanged() } }
    @IBInspectable public var color: UIColor = UIColor.gray { didSet { owner?.rangesChanged() } }
    @IBInspectable public var label: String = "" { didSet { owner?.rangesChanged() } }
    @IBInspectable public var order: Int = 0 { didSet { if let owner = owner { owner.rangesOrderChanged(owner._ranges) } } }
    fileprivate weak var owner: GaugeView?
	
}

@IBDesignable
class GaugeView: UIView {
// MARK: Backgound Properties
	@IBInspectable public var showInnerRim = false { didSet { recalcFaceRect() } }
	@IBInspectable public var innerRimWidth: CGFloat = 0.05 { didSet { recalcFaceRect() } }
	@IBInspectable public var innerRimBorderWidth: CGFloat = 0.005 { didSet { recalcFaceRect() } }
	public var innerBackgroundStyle: GaugeViewInnerBackgroundStyle = .gradient { didSet { backgroundChanged() } }
	@IBInspectable public var innerBackgroundStyleStr: String {
		get{return innerBackgroundStyle.rawValue}
		set{innerBackgroundStyle = GaugeViewInnerBackgroundStyle(rawValue: newValue) ?? .gradient}
	}
	
// MARK: Scale Metrics Properties
	@IBInspectable public var scalePosition: CGFloat = 0.025 { didSet { recalcScaleRect() } }
	@IBInspectable public var scaleStartAngle: CGFloat = 30.0 { didSet { scaleMetricsChanged() } }
	@IBInspectable public var scaleEndAngle: CGFloat = 330.0 { didSet { scaleMetricsChanged() } }
	@IBInspectable public var scaleDivisions: CGFloat = 12.0 { didSet { scaleMetricsChanged() } }
	@IBInspectable public var scaleSubdivisions: CGFloat = 10.0 { didSet { scaleMetricsChanged() } }
	
// MARK: Scale Drawing Properties
	@IBInspectable public var useScaleDivisionColor = false { didSet { scaleChanged() } }
	public var scaleSubdivisionsAligment: GaugeViewSubdivisionsAlignment = .top { didSet { scaleChanged() } }
	@IBInspectable public var scaleSubdivisionsAligmentStr: String {
		get{return scaleSubdivisionsAligment.rawValue}
		set{scaleSubdivisionsAligment = GaugeViewSubdivisionsAlignment(rawValue: newValue) ?? .top}
	}
	@IBInspectable public var scaleDivisionsLength: CGFloat = 0.045 { didSet { scaleChanged() } }
	@IBInspectable public var scaleDivisionsWidth: CGFloat = 0.01 { didSet { scaleChanged() } }
	@IBInspectable public var scaleSubdivisionsLength: CGFloat = 0.015 { didSet { scaleChanged() } }
	@IBInspectable public var scaleSubdivisionsWidth: CGFloat = 0.01 { didSet { scaleChanged() } }
	@IBInspectable public var scaleDivisionColor: UIColor = UIColor.white { didSet { scaleChanged() } }
	@IBInspectable public var scaleSubDivisionColor: UIColor = UIColor.white { didSet { scaleChanged() } }
	@IBInspectable public var cyclic = false { didSet { scaleChanged() } }
	@IBInspectable public var scaleFont: UIFont = UIFont(name: "Helvetica-Bold", size: 0.05)! { didSet { scaleChanged() } }
	public var scaleDescription: (CGFloat, Int) -> String = { value, _ in String(format: "%0.0f", value) } { didSet { scaleChanged() } }
	
// MARK: Ranges Properties
	@IBInspectable public var showRangeLabels = true { didSet { recalcScaleRect() } }
	@IBInspectable public var rangeLabelsWidth: CGFloat = 0.05 { didSet { recalcScaleRect() } }
	@IBInspectable public var rangeLabelsFont: UIFont = UIFont(name: "Helvetica", size: 0.05)! { didSet { rangesChanged() } }
	@IBInspectable public var rangeLabelsFontColor: UIColor = UIColor.black { didSet { rangesChanged() } }
	@IBInspectable public var rangeLabelsFontKerning: CGFloat = 1.02 { didSet { rangesChanged() } }
	@IBOutlet var ranges: [GaugeRange] {
		get { return _ranges }
		set { rangesOrderChanged(newValue) }
	}
	fileprivate var _ranges: [GaugeRange] = [] {
		didSet {
			for range in _ranges { range.owner = self }
		}
	}
	
// MARK: Indicator Properties
	// Indicator // TODO have configurable with more states
	@IBInspectable public var indicatorImage: UIImage? { didSet { indicatorChanged() } }
	@IBInspectable public var indicatorTint: UIColor? { didSet { indicatorChanged() } }
	@IBInspectable public var indicatorVerticalOffset: CGFloat = 0.3 { didSet { indicatorChanged() } }
	@IBInspectable public var indicatorSize = CGSize(width: 0.16, height: 0.16) { didSet { indicatorChanged() } }

// MARK: Label Properties
	@IBInspectable public var labelColor: UIColor = UIColor.white { didSet { indicatorChanged() } }
	@IBInspectable public var labelVerticalOffset: CGFloat = 0.6 { didSet { indicatorChanged() } }
	@IBInspectable public var labelFont: UIFont = UIFont(name: "Helvetica", size: 0.06)! { didSet { indicatorChanged() } }
	@IBInspectable public var label: String = "" { didSet { indicatorChanged() } }
	
// MARK: Needle Properties
	@IBInspectable public var needleWidth: CGFloat = 0.035 { didSet { needleChanged() } }
	@IBInspectable public var needleHeight: CGFloat = 0.34 { didSet { needleChanged() } }
	public var needleStyle: GaugeViewNeedleStyle = .threeD { didSet { needleChanged() } }
	@IBInspectable public var needleStyleStr: String {
		get{return needleStyle.rawValue}
		set{needleStyle = GaugeViewNeedleStyle(rawValue: newValue) ?? .threeD}
	}
	
// MARK: Needle Screw Properties
	@IBInspectable public var needleScrewRadius: CGFloat = 0.04 { didSet { needleScrewChanged() } }
	public var needleScrewStyle: GaugeViewNeedleScrewStyle = .gradient { didSet { needleScrewChanged() } }
	@IBInspectable public var needleScrewStyleStr: String {
		get{return needleScrewStyle.rawValue}
		set{needleScrewStyle = GaugeViewNeedleScrewStyle(rawValue: newValue) ?? .gradient}
	}
	
// MARK: Value Properties
	@IBInspectable public var value: CGFloat {
		get { return _value }
		set { setValue( newValue, animated: true)}
	}
	@IBInspectable public var minValue: CGFloat = 0.0 { didSet { scaleMetricsChanged() } }
	@IBInspectable public var maxValue: CGFloat = 240.0 { didSet { scaleMetricsChanged() } }
	
// MARK: Life Cycle
	public override init(frame: CGRect) {
		super.init(frame: frame)
		setupLayers()
	}

	public required init?(coder aDecoder: NSCoder) {
    	super.init(coder: aDecoder)
    	setupLayers()
    }
	
// MARK: Layers
	override public func layoutSublayers(of layer: CALayer) {
		if layer === self.layer {
			backgroundLayer.alignTo(boounds: layer.bounds)
		}
	}
	
	private class DrawingLayer: CALayer {
		var draw : ((CGContext)->())!
		
		override func draw(in context: CGContext) {
			UIGraphicsPushContext(context)
			defer { UIGraphicsPopContext() }
			let s = self.bounds.size
			context.scaleBy(x: s.width, y: s.height)
        	draw(context)
        }
		
        func alignTo(boounds: CGRect) {
        	self.transform = CATransform3DIdentity
			self.frame = boounds
			self.sublayers?.forEach {
				if let layer = $0 as? DrawingLayer {
					layer.alignTo(boounds: self.bounds)
				}
			}
        }
	}
	
	private let backgroundLayer = DrawingLayer()
	private let scaleLayer = DrawingLayer()
	private let indicatorLayer = DrawingLayer()
	private let rangeLayer = DrawingLayer()
	private let needleLayer = DrawingLayer()
	private let needleScrewLayer = DrawingLayer()
	
	private func setupLayers() {
		self.clipsToBounds = false
		self.isOpaque = false
		self.backgroundColor = UIColor.clear
		
		backgroundLayer.draw = { [weak self] ctx in
			self?.drawFace(in: ctx)
			self?.drawRim(in: ctx)
		}
		self.layer.addSublayer(backgroundLayer)
		
		scaleLayer.draw = { [weak self] ctx in
			self?.drawScale(in: ctx)
		}
		self.backgroundLayer.addSublayer(scaleLayer)
		
		indicatorLayer.draw = { [weak self] ctx in
			self?.drawIndicator(in: ctx)
			self?.drawLabel(in: ctx)
		}
		self.backgroundLayer.addSublayer(indicatorLayer)
		
		rangeLayer.draw = { [weak self] ctx in
			self?.drawRangeLabels(in: ctx)
		}
		self.backgroundLayer.addSublayer(rangeLayer)
		
		needleLayer.draw = { [weak self] ctx in
			self?.drawNeedle(in: ctx)
		}
		self.backgroundLayer.addSublayer(needleLayer)
		
		needleScrewLayer.draw = { [weak self] ctx in
			self?.drawNeedleScrew(in: ctx)
		}
		self.backgroundLayer.addSublayer(needleScrewLayer)
		
		recalcFaceRect()
	}
	
// MARK: Rect cache
	private let fullCenter: CGPoint = CGPoint(x: 0.5, y: 0.5)
	private let fullRect: CGRect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
	private var faceRect: CGRect = CGRect.zero
	private var innerRimRect: CGRect = CGRect.zero
	private var innerRimBorderRect: CGRect = CGRect.zero
	private var rangeLabelsRect: CGRect = CGRect.zero
	private var scaleRect: CGRect = CGRect.zero
	
	private func recalcFaceRect() {
		let innerRimBorderWidth = self.showInnerRim ? self.innerRimBorderWidth : 0.0
		let innerRimWidth = self.showInnerRim ? self.innerRimWidth : 0.0
		innerRimRect = fullRect
		innerRimBorderRect = CGRect(x: innerRimRect.origin.x + innerRimBorderWidth, y: innerRimRect.origin.y + innerRimBorderWidth, width: innerRimRect.size.width - 2.0 * innerRimBorderWidth, height: innerRimRect.size.height - 2.0 * innerRimBorderWidth)
		faceRect = CGRect(x: innerRimRect.origin.x + innerRimWidth, y: innerRimRect.origin.y + innerRimWidth, width: innerRimRect.size.width - 2.0 * innerRimWidth, height: innerRimRect.size.height - 2.0 * innerRimWidth)
		backgroundChanged()
		indicatorChanged()
		recalcScaleRect()
		needleChanged()
		needleScrewChanged()
	}
	
	private func recalcScaleRect() {
		rangeLabelsRect = CGRect(x: faceRect.origin.x + (showRangeLabels ? rangeLabelsWidth : 0.0), y: faceRect.origin.y + (showRangeLabels ? rangeLabelsWidth : 0.0), width: faceRect.size.width - 2 * (showRangeLabels ? rangeLabelsWidth : 0.0), height: faceRect.size.height - 2 * (showRangeLabels ? rangeLabelsWidth : 0.0))
		scaleRect = CGRect(x: rangeLabelsRect.origin.x + scalePosition, y: rangeLabelsRect.origin.y + scalePosition, width: rangeLabelsRect.size.width - 2 * scalePosition, height: rangeLabelsRect.size.height - 2 * scalePosition)
		scaleMetricsChanged()
	}
	
// MARK: Face
	private func backgroundChanged() {
		self.backgroundLayer.setNeedsDisplay()
	}
	
	private func drawFace(in context: CGContext) {
		switch innerBackgroundStyle {
			case .none:
				break
			case .gradient:
            // Default Face
				let baseSpace = CGColorSpaceCreateDeviceRGB()
				let gradient = CGGradient(colorsSpace: baseSpace,
					colors: [UIColor(96, 96, 96).cgColor, UIColor(68, 68, 68).cgColor, UIColor(32, 32, 32).cgColor] as CFArray,
					locations: [0.35, 0.96, 0.99])
				context.addEllipse(in: faceRect)
				context.clip()
				context.drawRadialGradient(gradient!, startCenter: fullCenter, startRadius: 0, endCenter: fullCenter, endRadius: faceRect.size.width / 2.0, options: CGGradientDrawingOptions.drawsAfterEndLocation)
            // Shadow
				let baseSpace2 = CGColorSpaceCreateDeviceRGB()
				let gradient2 = CGGradient(colorsSpace: baseSpace2,
					colors: [UIColor(40, 96, 170, 60).cgColor, UIColor(15, 34, 98, 80).cgColor, UIColor(0, 0, 0, 120).cgColor, UIColor(0, 0, 0, 140).cgColor] as CFArray,
					locations: [0.60, 0.85, 0.96, 0.99])
				context.addEllipse(in: faceRect)
				context.clip()
				context.drawRadialGradient(gradient2!, startCenter: fullCenter, startRadius: 0, endCenter: fullCenter, endRadius: faceRect.size.width / 2.0, options: CGGradientDrawingOptions.drawsAfterEndLocation)
			// Border
				context.setLineWidth(0.005)
				context.setStrokeColor(UIColor(81, 84, 89, 160).cgColor)
				context.addEllipse(in: faceRect)
				context.strokePath()
			case .flat:
            	let EXTERNAL_RING_RADIUS: CGFloat = 0.24
             	let INTERNAL_RING_RADIUS: CGFloat = 0.1
			 // External circle
				context.addEllipse(in: CGRect(x: fullCenter.x - EXTERNAL_RING_RADIUS, y: fullCenter.y - EXTERNAL_RING_RADIUS, width: EXTERNAL_RING_RADIUS * 2.0, height: EXTERNAL_RING_RADIUS * 2.0))
				context.setFillColor(UIColor(255, 104, 97).cgColor)
				context.fillPath()
			// Inner circle
				context.addEllipse(in: CGRect(x: fullCenter.x - INTERNAL_RING_RADIUS, y: fullCenter.y - INTERNAL_RING_RADIUS, width: INTERNAL_RING_RADIUS * 2.0, height: INTERNAL_RING_RADIUS * 2.0))
				context.setFillColor(UIColor(242, 99, 92).cgColor)
				context.fillPath()
		}
	}
	
	// TODO: draw outer rim
	private func drawRim(in context: CGContext) {
	}
	
// MARK: Scale
	private func scaleChanged() {
		self.scaleLayer.setNeedsDisplay()
	}
	
	private func scaleMetricsChanged() {
		self.recalcScaleMtrics()
		self.scaleLayer.setNeedsDisplay()
		self.rangesChanged()
		self.valueChanged()
	}
	
    private var divisionValue: CGFloat = 0.0
    private var subdivisionAngle: CGFloat = 0.0
	
	func recalcScaleMtrics() {
		divisionValue = (maxValue - minValue) / scaleDivisions
		subdivisionAngle = (scaleEndAngle - scaleStartAngle) / (scaleDivisions * scaleSubdivisions)
	}
	
	private func valueFor(tick: Int) -> CGFloat {
		return CGFloat(tick) * (divisionValue / scaleSubdivisions) + minValue
	}
	
	private func drawScale(in context: CGContext) {
		context.rotate(fromCenter: fullCenter, withAngle: (180.0 + scaleStartAngle).degToRad)
		var totalTicks: Int = Int(scaleDivisions * scaleSubdivisions)
		if cyclic == false {
			totalTicks += 1
		}
		var offset: CGFloat = 0.0
		switch scaleSubdivisionsAligment {
			case .center:
				offset = (scaleDivisionsLength - scaleSubdivisionsLength) / 2.0
			case .bottom:
				offset = scaleDivisionsLength - scaleSubdivisionsLength
			case .top:
				break
		}
		for i in 0..<totalTicks {
			let y1 = scaleRect.origin.y
			let y2 = y1 + scaleSubdivisionsLength
			let y3 = y1 + scaleDivisionsLength
			let value = self.valueFor(tick: i)
			let div = (maxValue - minValue) / scaleDivisions
			let mod = CGFloat(Int(value) % Int(div))
			// Division
			if (abs(mod - 0) < 0.000001) || (abs(mod - div) < 0.000001) {
            	// Initialize Core Graphics settings
				let color = useScaleDivisionColor ? scaleDivisionColor : rangeColor(forValue: value) ?? scaleDivisionColor
				context.setStrokeColor(color.cgColor)
				context.setLineWidth(scaleDivisionsWidth)
				// Draw tick
				context.move(to: CGPoint(x: 0.5, y: y1))
				context.addLine(to: CGPoint(x: 0.5, y: y3))
				context.strokePath()
				// Draw label
				let valueString = scaleDescription(value, i)
				let stringAttrs: [NSAttributedString.Key : Any] = [NSAttributedString.Key.font: scaleFont, NSAttributedString.Key.foregroundColor: color]
				let attrStr = NSAttributedString(string: valueString, attributes: stringAttrs)
				let fontWidth = valueString.size(withAttributes: stringAttrs)
				attrStr.draw(at: CGPoint(x: 0.5 - fontWidth.width / 2.0, y: y3 + 0.005))
			}
			// Subdivision
			else {
				// Initialize Core Graphics settings
				let color = useScaleDivisionColor ? scaleDivisionColor : rangeColor(forValue: value) ?? scaleDivisionColor
				context.setStrokeColor(color.cgColor)
				context.setLineWidth(scaleSubdivisionsWidth)
				context.move(to: CGPoint(x: 0.5, y: y1))
				// Draw tick
				context.move(to: CGPoint(x: 0.5, y: y1 + offset))
				context.addLine(to: CGPoint(x: 0.5, y: y2 + offset))
				context.strokePath()
			}
			// Rotate to next tick
			context.rotate(fromCenter: fullCenter, withAngle: subdivisionAngle.degToRad)
		}
	}
	
// MARK: Indicators
	private func indicatorChanged() {
		self.indicatorLayer.setNeedsDisplay()
	}
	
	private func drawIndicator(in context: CGContext) {
		if var image = self.indicatorImage {
			if let tint = self.indicatorTint {
				image = image.tinted(with: tint)!
			}
			let rect = CGRect(
				x: fullCenter.x - indicatorSize.width / 2.0,
				y: indicatorVerticalOffset - indicatorSize.height / 2.0,
				width: indicatorSize.width,
				height: indicatorSize.height)
			image.draw(in: rect)
		}
	}
	
	private func drawLabel(in context: CGContext) {
		if label.isEmpty == false {
			let stringAttrs: [NSAttributedString.Key : Any] = [NSAttributedString.Key.font: labelFont, NSAttributedString.Key.foregroundColor: labelColor]
			let attrStr = NSAttributedString(string: label, attributes: stringAttrs)
			let size = label.size(withAttributes: stringAttrs as [NSAttributedString.Key : Any])
			attrStr.draw(at: CGPoint(x: fullCenter.x - size.width / 2.0, y: labelVerticalOffset))
		}
	}
	
// MARK: Ranges
	fileprivate func rangesChanged() {
		if useScaleDivisionColor == false {
			scaleChanged()
		}
		rangeLayer.setNeedsDisplay()
	}
	
	fileprivate func rangesOrderChanged(_ ranges: [GaugeRange]) {
		_ranges = ranges.sorted { $0.order < $1.order } // IB does not guarantee order
	}
	
	fileprivate func rangeColor(forValue value: CGFloat) -> UIColor? {
		if _ranges.count > 0 {
			let length = _ranges.count
			for i in 0..<length - 1 {
				if value < _ranges[i].value {
					return _ranges[i].color
				}
			}
			if value <= (_ranges[length - 1]).value {
				return _ranges[length - 1].color
			}
		}
		return nil
	}
	
	private func drawRangeLabels(in context: CGContext) {
		if showRangeLabels {
			context.rotate(fromCenter: fullCenter, withAngle: (90.0 + scaleStartAngle).degToRad)
			let maxAngle = scaleEndAngle - scaleStartAngle
			var lastStartAngle: CGFloat = 0.0
			for range in _ranges {
				// Range value
				let value = range.value
				let valueAngle = (value - minValue) / (maxValue - minValue) * maxAngle
				// Range curved shape
				context.addArc(center: fullCenter, radius: rangeLabelsRect.size.width / 2.0 + 0.01, startAngle: valueAngle.degToRad, endAngle: lastStartAngle.degToRad, clockwise: true)
				context.setStrokeColor(range.color.cgColor)
				context.setLineWidth(rangeLabelsWidth)
				context.strokePath()
				// Range curved label
				drawString(at: context, string: range.label, startAngle: lastStartAngle.degToRad, endAngle: valueAngle.degToRad)
				lastStartAngle = valueAngle
			}
		}
	}

	func drawString(at context: CGContext, string text: String, startAngle: CGFloat, endAngle: CGFloat) {
		guard startAngle < endAngle else { return }
		context.saveGState()
		defer { context.restoreGState() }
		
	// TODO radius and baseline not quite right
		let stringAttrs: [NSAttributedString.Key : Any] = [NSAttributedString.Key.font: rangeLabelsFont, NSAttributedString.Key.foregroundColor: rangeLabelsFontColor]
		let textSize = text.size(withAttributes: stringAttrs)
		let radius = rangeLabelsRect.size.width / 2.0 + 0.008
		let perimeter = 2.0 * .pi * radius
		let textAngle = textSize.width / perimeter * 2.0 * .pi * rangeLabelsFontKerning
		let offset = ((endAngle - startAngle) - CGFloat(textAngle)) / 2.0
		var letterPosition: CGFloat = 0.0
		var lastLetter = ""
		context.rotate(fromCenter: fullCenter, withAngle: startAngle + CGFloat(offset))
		for character in text {
			let letter = String(character)
			let attrStr = NSAttributedString(string: letter, attributes: stringAttrs)
			let charSize = letter.size(withAttributes: stringAttrs)
			let totalWidth = "\(lastLetter)\(letter)".size(withAttributes: stringAttrs).width
			let currentLetterWidth = letter.size(withAttributes: stringAttrs).width
			let lastLetterWidth = lastLetter.size(withAttributes: stringAttrs).width
			let kerning = (lastLetterWidth) != 0.0 ? 0.0 : ((currentLetterWidth + lastLetterWidth) - totalWidth)
			letterPosition += (charSize.width / 2.0) - kerning
       		let angle = (letterPosition / perimeter * 2 * .pi) * rangeLabelsFontKerning
        	let letterPoint = CGPoint(x: (radius - charSize.height / 2.0) * cos(angle) + fullCenter.x, y: (radius - charSize.height / 2.0) * sin(angle) + fullCenter.y)
        	context.saveGState()
        	context.translateBy(x: letterPoint.x, y: letterPoint.y)
			let rotationTransform = CGAffineTransform(rotationAngle: angle + .pi / 2.0)
			context.concatenate(rotationTransform)
			context.translateBy(x: -letterPoint.x, y: -letterPoint.y)
			attrStr.draw(at: CGPoint(x: letterPoint.x - charSize.width / 2.0, y: letterPoint.y - charSize.height))
       		context.restoreGState()
        	letterPosition += charSize.width / 2.0
        	lastLetter = letter
		}
	}

// MARK: Needle
	private func needleChanged() {
		self.needleLayer.setNeedsDisplay()
	}
	
	private func drawNeedle(in context: CGContext) {
	    switch needleStyle {
			case .none:
				break
			case .threeD:
				// Left Needle
				context.move(to: CGPoint(x: fullCenter.x, y: fullCenter.y))
				context.addLine(to: CGPoint(x: fullCenter.x - needleWidth, y: fullCenter.y))
				context.addLine(to: CGPoint(x: fullCenter.x, y: fullCenter.y - needleHeight))
				context.closePath()
				context.setFillColor(UIColor(176, 10, 19).cgColor)
				context.fillPath()
				// Right Needle
				context.move(to: CGPoint(x: fullCenter.x, y: fullCenter.y))
				context.addLine(to: CGPoint(x: fullCenter.x + needleWidth, y: fullCenter.y))
				context.addLine(to: CGPoint(x: fullCenter.x, y: fullCenter.y - needleHeight))
				context.closePath()
				context.setFillColor(UIColor(252, 18, 30).cgColor)
				context.fillPath()
			case .flatThin:
				context.move(to: CGPoint(x: fullCenter.x - needleWidth, y: fullCenter.y))
				context.addLine(to: CGPoint(x: fullCenter.x + needleWidth, y: fullCenter.y))
				context.addLine(to: CGPoint(x: fullCenter.x, y: fullCenter.y - needleHeight))
				context.closePath()
				context.setFillColor(UIColor(255, 104, 97).cgColor)
				context.setStrokeColor(UIColor(255, 104, 97).cgColor)
				context.setLineWidth(0.005)
				context.fillPath()
				context.strokePath()
		}
	}
	
// MARK: Needle Skrew
	private func needleScrewChanged() {
		needleScrewLayer.setNeedsDisplay()
	}
	
	private func drawNeedleScrew(in context: CGContext) {
		switch needleScrewStyle {
			case .none:
				break
			case .gradient:
				// Screw drawing
				let knob = CGRect(x: fullCenter.x - needleScrewRadius, y: fullCenter.y - needleScrewRadius, width: needleScrewRadius * 2.0, height: needleScrewRadius * 2.0)
				context.addEllipse(in: knob)
				context.setFillColor(UIColor(171, 171, 171).cgColor)
				context.setStrokeColor(UIColor(81, 84, 89, 200).cgColor)
				context.setLineWidth(0.005)
				context.fillPath()
				context.strokePath()
			case .plain:
				// Screw drawing
				let knob = CGRect(x: fullCenter.x - needleScrewRadius, y: fullCenter.y - needleScrewRadius, width: needleScrewRadius * 2.0, height: needleScrewRadius * 2.0)
				context.addEllipse(in: knob)
				context.setFillColor(UIColor(68, 84, 105).cgColor)
				context.fillPath()
		}
	}
	
// MARK: Value
	private var _value: CGFloat = 0.0

	private func needleRadians(forValue value: CGFloat) -> CGFloat {
		return (180.0 + scaleStartAngle + (ranged(value: value) - minValue) / (maxValue - minValue) * (scaleEndAngle - scaleStartAngle)).degToRad
	}
	
	private func ranged(value: CGFloat) -> CGFloat {
		return value > maxValue ? maxValue : value < minValue ? minValue : value
	}
	// TODO: the CATransform3DMakeRotation is rvidually rotating more than just the Z axis
	private func valueChanged() {
		let radians = needleRadians(forValue: _value)
		let finalTransform = CATransform3DMakeRotation(radians, 0.0, 0.0, 1.0)
		needleLayer.transform = finalTransform
	}
	
	public func setValue(_ newValue: CGFloat, animated: Bool, duration: TimeInterval = 0.8, completion: ((_ finished: Bool) -> Void)? = nil) {
		let lastValue = _value
		_value = newValue
		if animated {
			// Needle animation to target value
			let firstRadians = needleRadians(forValue: lastValue)
			let lastRadians = needleRadians(forValue: _value)
			let middleRadians: CGFloat
			// TODO: make these work correctly
			if cyclic {
				middleRadians = lastValue + (((lastValue + (value - lastValue) / 2.0) >= 0) ? (value - lastValue) / 2.0 : (lastValue - _value) / 2.0)
			}
			else {
				middleRadians = (firstRadians + lastRadians) / 2.0
				print("\(firstRadians) -> \(middleRadians) -> \(lastRadians)")
			}
			//let firstTransform = CATransform3DMakeRotation(firstRadians, 0.0, 0.0, 1.0)
			// An intermediate "middle" value is used to make sure the needle will follow the right rotation direction
			let middleTransform = CATransform3DMakeRotation(middleRadians, 0.0, 0.0, 1.0)
			let finalTransform = CATransform3DMakeRotation(lastRadians, 0.0, 0.0, 1.0)
			let animation = CAKeyframeAnimation(keyPath: "transform")
			animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
			animation.isRemovedOnCompletion = true
			animation.duration = duration
			animation.values = [/*NSValue(caTransform3D: firstTransform),*/ NSValue(caTransform3D: middleTransform), NSValue(caTransform3D: finalTransform)]
			needleLayer.add(animation, forKey: kCATransition)
		}
		else {
			valueChanged()
		}
	}
}
