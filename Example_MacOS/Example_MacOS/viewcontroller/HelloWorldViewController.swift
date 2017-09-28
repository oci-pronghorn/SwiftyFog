//
//  ViewController.swift
//  Example_MacOS
//
//  Created by Tobias Schweiger on 9/27/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Cocoa
import SwiftyFog_Mac

class HelloWorldViewController : NSViewController {
	
	var mqttControl: MQTTControl! {
		didSet {
			mqttControl.start()
		}
	}
	
	var mqtt: MQTTBridge!
	var subscription: MQTTSubscription?

	@IBOutlet weak var statusTextField: NSTextField!
	@IBOutlet weak var connectDisconnectButton: NSButton!
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}

	@IBAction func connectDisconnectPressed(_ sender: Any) {
		if mqttControl.started {
			mqttControl.stop()
		}
		else {
			mqttControl.start()
		}
	}
	
	@IBAction func publishFirstTestPressed(_ sender: Any) {
		mqtt.publish(MQTTMessage(topic: "HelloWorld/SayHello", qos: .atMostOnce)) { (success) in
			print("\(Date.nowInSeconds()) publishQos0: \(success)")
		}
	}
	
	@IBAction func unsubscribePressed(_ sender: Any) {
		print("unsubscribe!")
	}
	
	@IBAction func subscribeAllPressed(_ sender: Any) {
		print("subscribe!")
	}
	
	override var representedObject: Any? {
		didSet {
		// Update the view, if already loaded.
		}
	}

}

//TODO: Setting button title crashes the app. Presumably threading issue?
extension HelloWorldViewController {
	func mqtt(connected: MQTTConnectedState) {
		switch connected {
		case .started:
			break
		case .connected(_):
			break
		case .pinged(let status):
			switch status {
			case .notConnected:
				break
			case .sent:
				break
			case .skipped:
				break
			case .ack:
				break
			case .serverDied:
				break
			}
			break
		case .retry(_, _, _, _):
			break
		case .retriesFailed(_, _, _):
			break
		case .discconnected(_, _):
			break
		}
	}
}

