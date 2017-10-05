//
//  ARAppController.swift
//  FoggyAR
//
//  Created by Tobias Schweiger on 10/4/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation
import SwiftyFog_iOS

class ARAppController {
	var mqtt: (MQTTBridge & MQTTControl)!
	var network: NetworkReachability
	
	//weak var delegate: ARAppControllerDelegate?
	
	init(_ trainName: String) {
		self.network = NetworkReachability()
		
		// Create the concrete MQTTClient to connect to a specific broker
		let mqtt = MQTTClient(
			host: MQTTHostParams(host: "thejoveexpress.local")
		)

		self.mqtt = mqtt
	}
	
	public func goForeground() {
			// Network reachability can detect a disconnected state before the client
			network.start { [weak self] status in
				if status != .none {
					self?.mqtt.start()
				}
				else {
					self?.mqtt.stop()
				}
			}
	}
	
	public func goBackground() {
		// Be a good iOS citizen and shutdown the connection and timers
		mqtt.stop()
		network.stop()
	}
}
