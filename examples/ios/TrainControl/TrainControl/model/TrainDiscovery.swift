//
//  TrainDiscovery.swift
//  TrainControl
//
//  Created by David Giovannini on 8/2/18.
//  Copyright © 2018 Object Computing Inc. All rights reserved.
//

import Foundation
#if os(iOS)
import SwiftyFog_iOS
#elseif os(watchOS)
import SwiftFog_watch
#endif

public protocol TrainDiscoveryDelegate: class, SubscriptionLogging {
}

class TrainDiscovery {
	private var broadcaster: MQTTBroadcaster?
	
	public weak var delegate: TrainDiscoveryDelegate?
	
    public var mqtt: MQTTBridge! {
		didSet {
			broadcaster.assign(mqtt.broadcast(to: self, queue: DispatchQueue.main, topics: [
			// This callback mechanism is only looking at exact string matches
			// In order to support auto-discovery we need pattern matching!
				("+/lifecycle/feedback", .atLeastOnce, TrainDiscovery.feedbackLifecycle),
			]) {[weak self] (_, status) in self?.delegate?.onSubscriptionAck(status: status)})
		}
    }
	
    init() {
	}
	
	private func feedbackLifecycle(msg: MQTTMessage) {
		let alive: Bool = msg.payload.fogExtract()
		var displayName: String? = nil
		if alive {
			displayName = msg.payload.fogExtract()
			print("Discovered '\(displayName ?? "")' on \(msg.topic)" )
		}
	}
}

class KnownTrain {
	var displayName: String = ""
	var mqttHost: String = ""
	var mqttScope: String = ""
}

class KnownBroker {
	var displayName: String = ""
	var mqttHost: String = ""
}

class DiscoveredTrain {
	var displayName: String = ""
	var mqttHost: String = ""
	var mqttScope: String = ""
}
