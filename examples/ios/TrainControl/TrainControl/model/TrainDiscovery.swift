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

public struct DiscoveredTrain {
	var trainName: String
	var displayName: String?
}

public protocol TrainDiscoveryDelegate: class, SubscriptionLogging {
	func train(_ train: DiscoveredTrain, discovered: Bool, transitionary: Bool)
}

public class TrainDiscovery {
	private var trains: [String: DiscoveredTrain] = [:]
	private var broadcaster: MQTTBroadcaster?
	
	public weak var delegate: TrainDiscoveryDelegate?
	
    public var mqtt: MQTTBridge! {
		didSet {
			broadcaster.assign(mqtt.broadcast(to: self, queue: DispatchQueue.main, topics: [
				("+/lifecycle/feedback", .atLeastOnce, TrainDiscovery.feedbackLifecycle),
			]) {[weak self] (_, status) in self?.delegate?.onSubscriptionAck(status: status)})
		}
    }
	
    public init() {
	}
	
	public var firstTrain: DiscoveredTrain? {
		return trains.first?.value
	}
	
	private func feedbackLifecycle(msg: MQTTMessage) {
		let existingCount = trains.count
		let topic = String(msg.topic)
		let trainName = String(topic.prefix(upTo: topic.firstIndex(of: "/")!))
		var cursor = 0
		let alive: Bool = msg.payload.fogExtract(&cursor)
		if alive {
			let displayName: String? = msg.payload.fogExtract(&cursor)
			if let existing = trains[trainName] {
				if let displayName = displayName, displayName != existing.displayName {
					trains[trainName]!.displayName = displayName
					delegate?.train(existing, discovered: true, transitionary: false)
				}
			}
			else {
				let new = DiscoveredTrain(trainName: trainName, displayName: displayName)
				trains[trainName] = new
				delegate?.train(new, discovered: true, transitionary: existingCount == 0)
			}
		}
		else {
			if let existing = trains[trainName] {
				trains[trainName] = nil
				delegate?.train(existing, discovered: false, transitionary: existingCount == 1)
			}
		}
	}
}
/*
class KnownTrain {
	var displayName: String = ""
	var mqttHost: String = ""
	var mqttScope: String = ""
}

class KnownBroker {
	var displayName: String = ""
	var mqttHost: String = ""
}
*/

