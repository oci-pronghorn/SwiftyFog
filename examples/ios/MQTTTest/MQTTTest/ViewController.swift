//
//  TestingViewController.swift
//  TrainControl
//
//  Created by David Giovannini on 8/21/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import UIKit
@testable import SwiftyFog_iOS

class TestingViewController: UIViewController {
	var mqtt: MQTTBridge!
	var subscription: MQTTSubscription?

	override func viewDidLoad() {
		super.viewDidLoad()
	}

	@IBAction func publishQos0() {
		mqtt.publish(MQTTMessage(topic: "Bobs/Store/1", qos: .atMostOnce)) { (success) in
			print("\(Date.nowInSeconds()) publishQos0: \(success)")
		}
	}

	@IBAction func publishQos1() {
		mqtt.publish(MQTTMessage(topic: "Bobs/Store/1", qos: .atLeastOnce)) { (success) in
			print("\(Date.nowInSeconds()) publishQos1: \(success)")
		}
	}

	@IBAction func publishQos2() {
		mqtt.publish(MQTTMessage(topic: "Bobs/Store/1", qos: .exactlyOnce)) { (success) in
			print("\(Date.nowInSeconds()) publishQos2: \(success)")
		}
	}

	@IBAction func subAll0() {
		// Since we are possibly resubscribing to the same topic we force the unsubscribe first.
		// Otherwide we redundantly subscribe and then unsubscribe
		subscription = nil
		subscription = mqtt.subscribe(topics: [("Bobs/#", .atMostOnce)]) { status in
			print("\(Date.nowInSeconds()) subAll0: \(status)")
		}
	}

	@IBAction func subAll1() {
		subscription = nil
		subscription = mqtt.subscribe(topics: [("Bobs/#", .atLeastOnce)]) { status in
			print("\(Date.nowInSeconds()) subAll1: \(status)")
		}
	}

	@IBAction func subAll2() {
		subscription = nil
		subscription = mqtt.subscribe(topics: [("Bobs/#", .exactlyOnce)]) { status in
			print("\(Date.nowInSeconds()) subAll2: \(status)")
		}
	}

	@IBAction func unsubAll() {
		// Setting scription (or registration) to nil (or reassign) will unsubscribe
		subscription = nil
	}
}
