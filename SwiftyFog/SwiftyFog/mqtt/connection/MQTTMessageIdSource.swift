//
//  MQTTMessageIdSource.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/13/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

final class MQTTMessageIdSource {
	//TODO: do not assume not-in use after overflow
	private let mutex = ReadWriteMutex()
	private var id = UInt16(0)
	
	func fetch() -> UInt16 {
		return mutex.writing {
			if id == UInt16.max {
				id = 0
			}
			id += 1
			return id
		}
	}
	
	func release(id: UInt16) {
	}
}
