//
//  Train.swift
//  SwiftyFog_Example
//
//  Created by David Giovannini on 8/28/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import SwiftyFog

public protocol TrainDelegate: class {
	func train(handshake: Bool)
}

public class Train {
	private var broadcaster: MQTTBroadcaster?
	
    public var mqtt: MQTTBridge! {
		didSet {
			broadcaster = mqtt.broadcast(to: self, queue: DispatchQueue.main, topics: [
				("ping", .atLeastOnce, Train.receivePing)
			])
		}
    }
	
	private func receivePing(msg: MQTTMessage) {
	}
}
