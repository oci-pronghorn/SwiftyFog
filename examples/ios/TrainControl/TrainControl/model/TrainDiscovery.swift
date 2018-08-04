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
				("+/lifecycle/feedback", .atLeastOnce, TrainDiscovery.feedbackLifecycle),
			]) {[weak self] (_, status) in self?.delegate?.onSubscriptionAck(status: status)})
		}
    }
	
    init() {
	}
	
	private func feedbackLifecycle(msg: MQTTMessage) {
		var cursor = 0
		let alive: Bool = msg.payload.fogExtract(&cursor)
		var displayName: String? = nil
		if alive {
			displayName = msg.payload.fogExtract(&cursor)
			print("**** Discovered '\(displayName ?? "")' on \(msg.topic)" )
		}
		else {
			print("**** Lost on \(msg.topic)" )
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
