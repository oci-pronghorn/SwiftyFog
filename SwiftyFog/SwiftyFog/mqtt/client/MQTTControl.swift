//
//  MQTTControl.swift
//  SwiftyFog
//
//  Created by David Giovannini on 9/1/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

public protocol MQTTControl {
	var hostName: String { get }
	
	func start()
	
	var started: Bool { get }
	
	var connected: Bool { get }
	
	func stop()
}
