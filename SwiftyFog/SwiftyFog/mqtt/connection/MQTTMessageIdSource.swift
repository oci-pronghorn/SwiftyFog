//
//  MQTTMessageIdSource.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/13/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

public class MQTTMessageIdSource {
	private var id = UInt16(1)
	
	// TODO: make real
	public func fetch() -> UInt16 {
		id += 1
		return id
	}
	
	public func release(id: UInt16) {
	}
}
