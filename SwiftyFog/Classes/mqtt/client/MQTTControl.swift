//
//  MQTTControl.swift
//  SwiftyFog
//
//  Created by David Giovannini on 9/1/17.
//

import Foundation

public protocol MQTTControl {
	func start()
	
	var started: Bool { get }
	
	var connected: Bool { get }
	
	func stop()
}
