//
//  FogFeedbackValue.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/29/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

public protocol FogFeedbackModel {
	var hasFeedback: Bool { get }
	func reset()
	func assertValues()
}

public struct FogFeedbackValue<T: Equatable> {
	private let defaultValue: T
	private var controlled: T
	private var detected: T?
	public var value: T { return detected ?? controlled }
	
	public init(_ defaultValue: T) {
		self.defaultValue = defaultValue
		self.controlled = defaultValue
	}
	
	// Have we received any feedback?
	public var hasFeedback: Bool {
		return detected != nil
	}
	
	// Removes feedback value and resets controlled to default
	public mutating func reset() {
		self.controlled = defaultValue
		self.detected = nil
	}
	
	// True when both controlled and received match
	public var isSyncronize: Bool {
		return detected != nil && (controlled == detected)
	}
	
	// If control changed then invoke lambda
	@discardableResult
	public mutating func control(_ value: T, _ change: (T)->()) -> Bool {
		if !(value == controlled) {
			controlled = value
			change(value)
			return true
		}
		return false
	}
	
	public enum ReceiveApplied {
		case no
		case failed
		case asserted
		case yes
	
		var changed: Bool { return self == .asserted || self == .yes }
	}
	
	// If detected changed then invoke lambda
	@discardableResult
	public mutating func receive(_ value: T?, _ change: (T, Bool)->()) -> ReceiveApplied {
		guard let value = value else { return .failed }
		let wasNil = detected == nil
		if wasNil || !(value == detected) {
			detected = value
			change(value, wasNil)
			return wasNil ? .asserted : .yes
		}
		return .no
	}
}
