//
//  Pulsator.swift
//  Pulsator
//
//  Created by Shuichi Tsutsumi on 4/9/16.
//  Copyright © 2016 Shuichi Tsutsumi. All rights reserved.
//
//  Objective-C version: https://github.com/shu223/PulsingHalo

import UIKit
import QuartzCore

internal let kPulsatorAnimationKey = "pulsator"

@IBDesignable
class Pulsator: CAReplicatorLayer, CAAnimationDelegate {
    private let pulse = CALayer()
    private var animationGroup: CAAnimationGroup!
    private var alpha: CGFloat = 0.45
	
    @IBOutlet weak var embedIn: UIView? {
		didSet {
			oldValue?.layer.removeObserver(self, forKeyPath: #keyPath(CALayer.position), context: nil)
			if let embedIn = embedIn {
        		embedIn.layer.superlayer?.insertSublayer(self, below: embedIn.layer)
				embedIn.layer.addObserver(self, forKeyPath: #keyPath(CALayer.position), options: .new, context: nil)
            	self.position = embedIn.layer.position
			}
			else  {
				self.removeFromSuperlayer()
			}
        }
    }
	
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let objectView = object as? CALayer, objectView === embedIn?.layer, keyPath == #keyPath(CALayer.position) {
            self.position = objectView.position
        }
    }
	
	@IBInspectable var pulseColor: UIColor? {
		get {
            guard let backgroundColor = backgroundColor else { return nil }
            return UIColor(cgColor: backgroundColor)
		}
		set {
			self.backgroundColor = newValue?.cgColor
		}
	}

    override var backgroundColor: CGColor? {
        didSet {
            pulse.backgroundColor = backgroundColor
            guard let backgroundColor = backgroundColor else {return}
            let oldAlpha = alpha
            alpha = backgroundColor.alpha
            if alpha != oldAlpha {
                recreate()
            }
        }
    }
	
    @IBInspectable override var repeatCount: Float {
        didSet {
            if let animationGroup = animationGroup {
                animationGroup.repeatCount = repeatCount
            }
        }
    }
	
    // MARK: - Public Properties
    /// The number of pulse.
    @IBInspectable var numPulse: Int = 1 {
        didSet {
            if numPulse < 1 {
                numPulse = 1
            }
            instanceCount = numPulse
            updateInstanceDelay()
        }
    }
	
    ///	The radius of pulse.
    @IBInspectable var radius: CGFloat = 60 {
        didSet {
            updatePulse()
        }
    }
	
    /// The animation duration in seconds.
    @IBInspectable var animationDuration: CGFloat = 3 {
        didSet {
            updateInstanceDelay()
        }
    }
	
    /// If this property is `true`, the instanse will be automatically removed
    /// from the superview, when it finishes the animation.
    @IBInspectable var autoRemove = false
	
    /// fromValue for radius
    /// It must be smaller than 1.0
    @IBInspectable var fromValueForRadius: Float = 0.0 {
        didSet {
            if fromValueForRadius >= 1.0 {
                fromValueForRadius = 0.0
            }
            recreate()
        }
    }
	
    /// The value of this property should be ranging from @c 0 to @c 1 (exclusive).
    @IBInspectable var keyTimeForHalfOpacity: Float = 0.2 {
        didSet {
            recreate()
        }
    }
	
    /// The animation interval in seconds.
    @IBInspectable var pulseInterval: CGFloat = 0
	
    /// A function describing a timing curve of the animation.
    var timingFunction: CAMediaTimingFunction? = CAMediaTimingFunction(name: convertToCAMediaTimingFunctionName(convertFromCAMediaTimingFunctionName(CAMediaTimingFunctionName.default))) {
        didSet {
            if let animationGroup = animationGroup {
                animationGroup.timingFunction = timingFunction
            }
        }
    }
	
    /// The value of this property showed a pulse is started
    var isPulsating: Bool {
        guard let keys = pulse.animationKeys() else {return false}
        return keys.count > 0
    }
	
    /// private properties for resuming
    private weak var prevSuperlayer: CALayer?
    private var prevLayerIndex: Int?
	
    // MARK: - Initializer
    override public init() {
        super.init()
		
        setupPulse()
		
        instanceDelay = 1
        repeatCount = MAXFLOAT
        backgroundColor = UIColor(
            red: 0, green: 0.455, blue: 0.756, alpha: 0.45).cgColor
    }
	
    override public init(layer: Any) {
        super.init(layer: layer)
    }
	
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
	
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
	
    // MARK: - Private Methods
	
    private func setupPulse() {
        pulse.contentsScale = UIScreen.main.scale
        pulse.opacity = 0
        addSublayer(pulse)
        updatePulse()
    }
	
    private func setupAnimationGroup() {
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale.xy")
        scaleAnimation.fromValue = fromValueForRadius
        scaleAnimation.toValue = 1.0
		scaleAnimation.duration = CFTimeInterval(animationDuration)
		
        let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
		opacityAnimation.duration = CFTimeInterval(animationDuration)
        opacityAnimation.values = [alpha, alpha * 0.5, 0.0]
        opacityAnimation.keyTimes = [0.0, NSNumber(value: keyTimeForHalfOpacity), 1.0]
		
        animationGroup = CAAnimationGroup()
        animationGroup.animations = [scaleAnimation, opacityAnimation]
		animationGroup.duration = Double(animationDuration + pulseInterval)
        animationGroup.repeatCount = repeatCount
        if let timingFunction = timingFunction {
            animationGroup.timingFunction = timingFunction
        }
        animationGroup.delegate = self
    }
	
    private func updatePulse() {
        let diameter: CGFloat = radius * 2
        pulse.bounds = CGRect(
            origin: CGPoint.zero,
            size: CGSize(width: diameter, height: diameter))
        pulse.cornerRadius = radius
        pulse.backgroundColor = backgroundColor
    }
	
    private func updateInstanceDelay() {
        guard numPulse >= 1 else { fatalError() }
        instanceDelay = Double(animationDuration + pulseInterval) / Double(numPulse)
    }
	
    private func recreate() {
        guard animationGroup != nil else { return }        // Not need to be recreated.
        stop()
        let when = DispatchTime.now() + Double(Int64(0.2 * double_t(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: when) { () -> Void in
            self.start()
        }
    }
	
    // MARK: - Internal Methods
	
	@objc func save() {
        prevSuperlayer = superlayer
        prevLayerIndex = prevSuperlayer?.sublayers?.index(where: {$0 === self})
    }

    @objc func resume() {
        if let prevSuperlayer = prevSuperlayer, let prevLayerIndex = prevLayerIndex {
            prevSuperlayer.insertSublayer(self, at: UInt32(prevLayerIndex))
        }
        if pulse.superlayer == nil {
            addSublayer(pulse)
        }
        let isAnimating = pulse.animation(forKey: kPulsatorAnimationKey) != nil
        // if the animationGroup is not nil, it means the animation was not stopped
        if let animationGroup = animationGroup, !isAnimating {
            pulse.add(animationGroup, forKey: kPulsatorAnimationKey)
        }
    }
	
    // MARK: - Public Methods
	
    /// Start the animation.
    func start() {
        setupPulse()
        setupAnimationGroup()
        pulse.add(animationGroup, forKey: kPulsatorAnimationKey)
    }
	
    /// Stop the animation.
    func stop() {
        pulse.removeAllAnimations()
        animationGroup = nil
    }
	
	
    // MARK: - Delegate methods for CAAnimation
	
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if let keys = pulse.animationKeys(), keys.count > 0 {
            pulse.removeAllAnimations()
        }
        pulse.removeFromSuperlayer()
		
        if autoRemove {
            removeFromSuperlayer()
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToCAMediaTimingFunctionName(_ input: String) -> CAMediaTimingFunctionName {
	return CAMediaTimingFunctionName(rawValue: input)
}

// Helper function inserted by Swift 4.2 migrator.
private func convertFromCAMediaTimingFunctionName(_ input: CAMediaTimingFunctionName) -> String {
	return input.rawValue
}
