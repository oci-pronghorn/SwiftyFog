//
//  FogRationalUi.swift
//  TrainControl
//
//  Created by David Giovannini on 10/1/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import UIKit
import SwiftyFog_iOS

public extension UISlider {
	public var rational: TrainRational {
		get {
			let numerator = TrainRational.ValueType(self.value)
			let denominator = TrainRational.ValueType(self.maximumValue)
			return TrainRational(num: numerator, den: denominator)
		}
		set {
			self.value = self.maximumValue * Float(newValue.num) / Float(newValue.den)
		}
	}
}

public extension ScrubControl {
	public var rational: TrainRational {
		get {
			let numerator = TrainRational.ValueType(self.value)
			let denominator = TrainRational.ValueType(self.maximumValue)
			return TrainRational(num: numerator, den: denominator)
		}
		set {
			self.value = self.maximumValue * Float(newValue.num) / Float(newValue.den)
		}
	}
}
