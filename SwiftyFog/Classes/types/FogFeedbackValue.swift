//
//  FogFeedbackValue.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/29/17.
//

import Foundation

public struct FogFeedbackValue<T: Equatable> {
	public private(set) var control: T
	public private(set) var detected: T?
	
	public var resolved: T {
		return detected ?? control
	}
	
	public init(_ defaultValue: T) {
		control = defaultValue
	}
	
	public mutating func feedbackCut() {
		detected = nil
	}
	
	public var isSyncronize: Bool {
		return detected != nil && (control == detected)
	}
	
	public var hasFeedback: Bool {
		return detected != nil
	}
	
	public mutating func controlled(_ value: T, change: (T)->()) {
		if !(value == control) {
			control = value
			change(value)
		}
	}
	
	public mutating func received(_ value: T, change: (T, Bool)->()) {
		let wasNil = detected == nil
		if wasNil || !(value == detected) {
			detected = value
			change(value, wasNil)
		}
	}
}
