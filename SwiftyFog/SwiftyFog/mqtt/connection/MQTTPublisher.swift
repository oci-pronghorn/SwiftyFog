//
//  MQTTPublisher.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/12/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

class MQTTPublisher {

	func publish() {
		// if qos 0, expect no response from server
		// if qos 1, expect pub ack
		// if qos 2, expect pub rec, send pub rel, rec pub comp
	}
	
	func receivePacket() {
	}
}
