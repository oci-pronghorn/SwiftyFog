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

public class Train: FogFeedbackModel {
	
	private var broadcaster: MQTTBroadcaster?
    //private var pingeChecker: DispatchSourceTimer?
	
	public weak var delegate: TrainDelegate?
	
    public var mqtt: MQTTBridge! {
		didSet {
			broadcaster = mqtt.broadcast(to: self, queue: DispatchQueue.main, topics: [
				("ping", .atLeastOnce, Train.receivePing)
			])
		}
    }
	
    init() {
	/*
			let keepAliveTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
			keepAliveTimer.schedule(deadline: .now() + .seconds(Int(clientPrams.keepAlive)), repeating: .seconds(Int(clientPrams.keepAlive)), leeway: .seconds(1))
			keepAliveTimer.setEventHandler { [weak self] in
				self?.pingFired()
			}
			self.keepAliveTimer = keepAliveTimer
			keepAliveTimer.resume()
		*/
	}
	
	public func reset() {
	}
	
	public var hasFeedback: Bool {
		return true
	}
	
	public func assertValues() {
	}
	
	private func receivePing(msg: MQTTMessage) {
	}
}
