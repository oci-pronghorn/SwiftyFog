//
//  Optional+RAII.swift
//  SwiftyFog
//
//  Created by David Giovannini on 7/20/18.
//  Copyright © 2018 Object Computing Inc. All rights reserved.
//

public extension Optional {
	public mutating func assign(_ factory: @autoclosure ()->(Wrapped?)) {
		self = nil // Execute deinit of old wrapped before factory (init of new wrapped)
		self = factory()
	}
}
