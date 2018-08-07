//
//  Data+MQTT.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/12/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation // Data

extension Data {
	mutating func mqttAppend <T: FixedWidthInteger> (_ rhs: T) {
		self.fogAppend(rhs)
	}
	
	mutating func mqttAppend(_ rhs: String.UTF8View) {
		self.fogAppend(rhs)
	}
	
	mutating func mqttAppend(_ value: Data) {
		self.fogAppend(UInt16(value.count))
		self.append(value)
	}
}
