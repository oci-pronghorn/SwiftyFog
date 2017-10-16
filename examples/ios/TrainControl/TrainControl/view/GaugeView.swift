//
//  GaugeView.swift
//  TrainControl
//
//  Created by David Giovannini on 10/16/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

public enum GaugeViewSubdivisionsAlignment : String {
    case top
    case center
    case bottom
}

public enum GaugeViewNeedleStyle : String {
    case threeD
    case flatThin
}

public enum GaugeViewNeedleScrewStyle : String {
    case gradient
    case plain
}

public enum GaugeViewInnerBackgroundStyle : String {
    case gradient
    case flat
}

public typealias GaugeViewScaleDescription = (Float, NSInteger) -> String

@IBDesignable
class GaugeView: UIView {
    @IBInspectable public var showInnerBackground = true
    	{ didSet { invalidateBackground() } }
    @IBInspectable public var showInnerRim = false
    	{ didSet { invalidateBackground() } }
    @IBInspectable public var innerRimWidth: CGFloat = 0.05
    	{ didSet { invalidateBackground() } }
    @IBInspectable public var innerRimBorderWidth: CGFloat = 0.005
    	{ didSet { invalidateBackground() } }
    public var innerBackgroundStyle = GaugeViewInnerBackgroundStyle.gradient
    	{ didSet { invalidateBackground() } }
    @IBInspectable public var needleWidth: CGFloat = 0.035
    	{ didSet { invalidateNeedle() } }
    @IBInspectable public var needleHeight: CGFloat = 0.34
    	{ didSet { invalidateNeedle() } }
    @IBInspectable public var needleScrewRadius: CGFloat = 0.04
    	{ didSet { invalidateNeedle() } }
    public var needleStyle = GaugeViewNeedleStyle.threeD
    	{ didSet { invalidateNeedle() } }
    public var needleScrewStyle = GaugeViewNeedleScrewStyle.gradient
    	{ didSet { invalidateNeedle() } }
    @IBInspectable public var scalePosition: CGFloat = 0.025
    	{ didSet { invalidateBackground() } }
    @IBInspectable public var scaleStartAngle: CGFloat = 30.0
		{ didSet { invalidateBackground() } }
    @IBInspectable public var scaleEndAngle: CGFloat = 330.0
		{ didSet { invalidateBackground() } }
    @IBInspectable public var scaleDivisions: CGFloat = 12.0
		{ didSet { invalidateBackground() } }
    @IBInspectable public var scaleSubdivisions: CGFloat = 10.0
		{ didSet { invalidateBackground() } }
    @IBInspectable public var isShowScaleShadow = true
		{ didSet { invalidateBackground() } }
    @IBInspectable public var isScaleIgnoreRangeColors = false
		{ didSet { invalidateBackground() } }
    public var scaleSubdivisionsAligment = GaugeViewSubdivisionsAlignment.top
		{ didSet { invalidateBackground() } }
    @IBInspectable public var scaleDivisionsLength: CGFloat = 0.045
		{ didSet { invalidateBackground() } }
    @IBInspectable public var scaleDivisionsWidth: CGFloat = 0.01
		{ didSet { invalidateBackground() } }
    @IBInspectable public var scaleSubdivisionsLength: CGFloat = 0.015
		{ didSet { invalidateBackground() } }
    @IBInspectable public var scaleSubdivisionsWidth: CGFloat = 0.01
		{ didSet { invalidateBackground() } }
    @IBInspectable public var scaleDivisionColor = UIColor(red: 68.0/255.0, green: 84.0/255.0, blue: 105.0/255.0, alpha: 1.0)
		{ didSet { invalidateBackground() } }
    @IBInspectable public var scaleSubDivisionColor = UIColor(red: 68.0/255.0, green: 84.0/255.0, blue: 105.0/255.0, alpha: 1.0)
		{ didSet { invalidateBackground() } }
    @IBInspectable public var showLastTick = true
		{ didSet { invalidateBackground() } }
    @IBInspectable public var scaleFont: UIFont?
		{ didSet { invalidateBackground() } }
    @IBInspectable public var value: Float = 0.0
		{ didSet { invalidateBackground() } }
    @IBInspectable public var minValue: Float = 0.0
		{ didSet { invalidateBackground() } }
    @IBInspectable public var maxValue: Float = 240.0
		{ didSet { invalidateBackground() } }
    @IBInspectable public var showRangeLabels = false
		{ didSet { invalidateBackground() } }
    @IBInspectable public var rangeLabelsWidth: CGFloat = 0.05
		{ didSet { invalidateBackground() } }
    @IBInspectable public var rangeLabelsFont: UIFont? = UIFont(name: "Helvetica", size: 0.05)
		{ didSet { invalidateBackground() } }
    @IBInspectable public var rangeLabelsFontColor = UIColor.white
		{ didSet { invalidateBackground() } }
    @IBInspectable public var rangeLabelsFontKerning: CGFloat = 0.0
		{ didSet { invalidateBackground() } }
    @IBInspectable public var rangeLabelsOffset: CGFloat = 0.0
		{ didSet { invalidateBackground() } }
    public var rangeValues = [Float]()
		{ didSet { invalidateBackground() } }
    public var rangeColors = [UIColor]()
		{ didSet { invalidateBackground() } }
    public var rangeLabels = [String]()
		{ didSet { invalidateBackground() } }
    @IBInspectable public var unitOfMeasurementColor = UIColor.white
		{ didSet { invalidateBackground() } }
    @IBInspectable public var unitOfMeasurementVerticalOffset: CGFloat = 0.0
		{ didSet { invalidateBackground() } }
    @IBInspectable public var unitOfMeasurementFont: UIFont? = UIFont(name: "Helvetica", size: 0.04)
		{ didSet { invalidateBackground() } }
    @IBInspectable public var unitOfMeasurement = ""
		{ didSet { invalidateBackground() } }
    @IBInspectable public var showUnitOfMeasurement = false
		{ didSet { invalidateBackground() } }
    public var scaleDescription: GaugeViewScaleDescription = {v, i in String(format: "%0.0f", v)}
		{ didSet { invalidateBackground() } }
	
    @IBInspectable public var innerBackgroundStyleStr: String {
    	get { return self.innerBackgroundStyle.rawValue }
		set { self.innerBackgroundStyle = GaugeViewInnerBackgroundStyle(rawValue: newValue) ?? GaugeViewInnerBackgroundStyle.gradient }
	}
    @IBInspectable public var needleStyleStr: String {
    	get { return self.needleStyle.rawValue }
		set { self.needleStyle = GaugeViewNeedleStyle(rawValue: newValue) ?? GaugeViewNeedleStyle.threeD }
	}
    @IBInspectable public var needleScrewStyleStr: String {
		get { return self.needleScrewStyle.rawValue }
		set { self.needleScrewStyle = GaugeViewNeedleScrewStyle(rawValue: newValue) ?? GaugeViewNeedleScrewStyle.gradient }
	}
    @IBInspectable public var scaleSubdivisionsAligmentStr: String {
		get { return self.scaleSubdivisionsAligment.rawValue }
		set { self.scaleSubdivisionsAligment = GaugeViewSubdivisionsAlignment(rawValue: newValue) ?? GaugeViewSubdivisionsAlignment.top }
	}
	
	public override init(frame: CGRect) {
        super.init(frame: frame)
        initDrawingRects()
		initScale()
    }

	public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initDrawingRects()
		initScale()
    }

	public func setValue(_ value: Float, animated: Bool = false, duration: TimeInterval = 0.8, completion: ((Bool)->())? = nil) {
	   	let lastValue = self.value
		updateValue(value)
		let middleValue: Float = lastValue + (((lastValue + (self.value - lastValue) / 2.0) >= 0) ? (self.value - lastValue) / 2.0 : (lastValue - self.value) / 2.0)
		// Needle animation to target value
		// An intermediate "middle" value is used to make sure the needle will follow the right rotation direction
		let animation = CAKeyframeAnimation(keyPath: "transform")
		animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
		animation.isRemovedOnCompletion = true
		animation.duration = animated ? duration : 0.0
		animation.delegate = self
		let lastTransform = CATransform3DMakeRotation(needleAngle(forValue: self.value), 0, 0, 1.0)
		animation.values = [
			NSValue(caTransform3D: CATransform3DMakeRotation(needleAngle(forValue: lastValue), 0, 0, 1.0)),
			NSValue(caTransform3D: CATransform3DMakeRotation(needleAngle(forValue: middleValue), 0, 0, 1.0)),
			NSValue(caTransform3D: lastTransform)]
		rootNeedleLayer?.transform = lastTransform
		rootNeedleLayer?.add(animation, forKey: kCATransition)
    }
	
	/* Drawing rects */
    private var fullRect = CGRect.zero
    private var innerRimRect = CGRect.zero
    private var innerRimBorderRect = CGRect.zero
    private var faceRect = CGRect.zero
    private var rangeLabelsRect = CGRect.zero
    private var scaleRect = CGRect.zero
    /* View center */
    private var center2 = CGPoint.zero
    /* Scale variables */
    private var scaleRotation: CGFloat = 0.0
    private var divisionValue: CGFloat = 0.0
    private var subdivisionValue: CGFloat = 0.0
    private var subdivisionAngle: CGFloat = 0.0
    /* Background image */
    private var background: UIImage?
    /* Needle layer */
    private var rootNeedleLayer: CALayer?
    /* Annimation completion */
    private var animationCompletion: ((Bool)->())? = nil
	
	private func initDrawingRects() {
	    center2 = CGPoint(x: 0.5, y: 0.5)
		fullRect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
		innerRimBorderWidth = showInnerRim ? innerRimBorderWidth : 0.0
		innerRimWidth = showInnerRim ? innerRimWidth : 0.0
		innerRimRect = fullRect
		innerRimBorderRect = CGRect(x: innerRimRect.origin.x + innerRimBorderWidth, y: innerRimRect.origin.y + innerRimBorderWidth, width: innerRimRect.size.width - 2 * innerRimBorderWidth, height: innerRimRect.size.height - 2 * innerRimBorderWidth)
		faceRect = CGRect(x: innerRimRect.origin.x + innerRimWidth, y: innerRimRect.origin.y + innerRimWidth, width: innerRimRect.size.width - 2 * innerRimWidth, height: innerRimRect.size.height - 2 * innerRimWidth)
		rangeLabelsRect = CGRect(x: faceRect.origin.x + (showRangeLabels ? rangeLabelsWidth : 0.0), y: faceRect.origin.y + (showRangeLabels ? rangeLabelsWidth : 0.0), width: faceRect.size.width - 2 * (showRangeLabels ? rangeLabelsWidth : 0.0), height: faceRect.size.height - 2 * (showRangeLabels ? rangeLabelsWidth : 0.0))
		scaleRect = CGRect(x: rangeLabelsRect.origin.x + scalePosition, y: rangeLabelsRect.origin.y + scalePosition, width: rangeLabelsRect.size.width - 2 * scalePosition, height: rangeLabelsRect.size.height - 2 * scalePosition)
	}
	
	func initScale() {
		scaleRotation = (scaleStartAngle + 180.0).truncatingRemainder(dividingBy: 360)
		divisionValue = CGFloat((maxValue - minValue) / Float(scaleDivisions))
		subdivisionValue = divisionValue / scaleSubdivisions
		subdivisionAngle = (scaleEndAngle - scaleStartAngle) / (scaleDivisions * scaleSubdivisions)
	}
	
	private func invalidateBackground() {
		background = nil
		initDrawingRects()
		initScale()
		setNeedsDisplay()
	}
	
	private func invalidateNeedle() {
		rootNeedleLayer?.removeAllAnimations()
		rootNeedleLayer?.sublayers = nil
		rootNeedleLayer = nil
		setNeedsDisplay()
	}
}

extension GaugeView {
	private func value(forTick tick: Int) -> Float {
		return Float(Float(tick) * Float(divisionValue / scaleSubdivisions) + minValue)
	}

	private func rangeColor(forValue value: Float) -> UIColor {
		let length: Int = rangeValues.count
		for i in 0..<length - 1 {
			if value < rangeValues[i] {
				return rangeColors[i]
			}
		}
		if value <= rangeValues[length - 1] {
			return rangeColors[length - 1]
		}
		return UIColor.clear
	}

	private func needleAngle(forValue value: Float) -> CGFloat {
		let diffAngle = (scaleEndAngle - scaleStartAngle)
		let fullRange = CGFloat(maxValue - minValue)
		let diffRange = CGFloat(value - minValue)
    	return ((.pi * scaleStartAngle + diffRange / fullRange * diffAngle) / 180.0) + .pi
	}
	
	private func updateValue(_ value: Float) {
		var newValue: Float
		if value > maxValue {
			newValue = maxValue
		}
		else if value < minValue {
			newValue = minValue
		}
		else {
			newValue = value
		}
		self.value = newValue
	}
}

extension GaugeView {
	override func draw(_ rect: CGRect) {
		if background == nil {
			// Create image context
			UIGraphicsBeginImageContextWithOptions(rect.size, false, UIScreen.main.scale)
			let context = UIGraphicsGetCurrentContext()!
			// Scale context for [0-1] drawings
			context.scaleBy(x: rect.size.width, y: rect.size.height)
			// Draw gauge background in image context
			drawGauge(context)
			// Save background
			background = UIGraphicsGetImageFromCurrentImageContext()
			UIGraphicsEndImageContext()
		}
		// Drawing background in view
		background?.draw(in: rect)
		if rootNeedleLayer == nil {
			// Initialize needle layer
			rootNeedleLayer = CALayer()
			// For performance puporse, the needle layer is not scaled to [0-1] range
			rootNeedleLayer!.frame = bounds
			layer.addSublayer(rootNeedleLayer!)
			// Draw needle
			drawNeedle()
			drawNeedleScrew()
			// Set needle current value
			setValue(value, animated: false)
		}
	}
	
	func drawGauge(_ context: CGContext) {
		if showInnerBackground {
			drawFace(context)
		}
		if showUnitOfMeasurement {
			drawText(context)
		}
		drawScale(context)
		if showRangeLabels {
			drawRangeLabels(context)
		}
	}

	func drawFace(_ context: CGContext) {
	}

	func drawText(_ context: CGContext) {
		context.setShadow(offset: CGSize(width: 0.05, height: 0.05), blur: 2.0)
		let font = unitOfMeasurementFont
		let color = unitOfMeasurementColor
		let stringAttrs: [NSAttributedStringKey : Any] = [.font: font, .foregroundColor: color]
		let attrStr = NSAttributedString(string: unitOfMeasurement, attributes: stringAttrs)
		let fontWidth: CGSize = unitOfMeasurement.size(withAttributes: stringAttrs)
		attrStr.draw(at: CGPoint(x: 0.5 - fontWidth.width / 2.0, y: unitOfMeasurementVerticalOffset))
	}
	
	func drawNeedle() {
	}
	
	func drawNeedleScrew() {
	}

	func drawScale(_ context: CGContext) {
	}

	func drawRangeLabels(_ context: CGContext) {
	}

}

extension GaugeView: CAAnimationDelegate {
	func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
		animationCompletion?(flag)
		animationCompletion = nil
	}
}
