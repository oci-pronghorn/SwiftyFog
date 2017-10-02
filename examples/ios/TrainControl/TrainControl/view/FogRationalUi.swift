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
	public var rational: FogRational<Int64> {
		get {
			let numerator = Int64(self.value)
			let denominator = Int64(self.maximumValue)
			return FogRational(num: numerator, den: denominator)
		}
		set {
			self.value = self.maximumValue * Float(newValue.num) / Float(newValue.den)
		}
	}
}

public extension ScrubControl {
	public var rational: FogRational<Int64> {
		get {
			let numerator = Int64(self.value)
			let denominator = Int64(self.maximumValue)
			return FogRational(num: numerator, den: denominator)
		}
		set {
			self.value = self.maximumValue * Float(newValue.num) / Float(newValue.den)
		}
	}
}
