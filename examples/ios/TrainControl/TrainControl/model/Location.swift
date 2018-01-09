//
//  Location.swift
//  TrainControl
//
//  Created by David Giovannini on 10/11/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation
import SwiftyFog_iOS

public protocol LocationDelegate: class {
	func train(heading: FogRational<Int64>)
    func train(motion: Bool)
}

class Location {
	private var broadcaster: MQTTBroadcaster?
	
	public weak var delegate: LocationDelegate?
	
    public var mqtt: MQTTBridge! {
		didSet {
			broadcaster = mqtt.broadcast(to: self, queue: DispatchQueue.main, topics: [
				("heading/feedback/", .atLeastOnce, Location.feedbackHeading),
                ("motion/feedback/", .atLeastOnce, Location.feedbackMotion)
			])
		}
    }
	
    init() {
	}
	
	private func feedbackHeading(msg: MQTTMessage) {
		if let heading: FogRational<Int64> = msg.payload.fogExtract() {
			delegate?.train(heading: heading)
		}
	}
    
    private func feedbackMotion(msg: MQTTMessage) {
        let motion: Bool = msg.payload.fogExtract()
        delegate?.train(motion: motion)
    }
}
