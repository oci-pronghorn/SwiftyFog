//
//  ViewController.swift
//  Example_MacOS
//
//  Created by Tobias Schweiger on 9/27/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Cocoa
import SwiftyFog_Mac

/* TODO: Maybe make the demo more interactive? i.e. actually able to receive and publish messages */
class HelloWorldViewController : NSViewController {
	
	var mqttControl: MQTTControl! {
		didSet {
			mqttControl.start()
		}
	}
	
	var mqtt: MQTTBridge!
	var subscription: MQTTSubscription?
	
	@IBOutlet weak var statusTextField: NSTextField!
	@IBOutlet var logTextView: NSTextView!
	@IBOutlet weak var connectDisconnectButton: NSButton!
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	func onLog(_ str: String) {
		DispatchQueue.main.async {
			let _ = self.view
			self.logTextView.textStorage?.append(NSAttributedString(string: "\(str)\n"))
			self.logTextView.scrollToEndOfDocument(self)
		}
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
		mqtt.publish(MQTTMessage(topic: "Test/SayHello", qos: .atMostOnce)) { (success) in
			print("\(Date.nowInSeconds()) publishQos0: \(success)")
		}
	}
	
	@IBAction func subscribeAllPressed(_ sender: Any) {
		// Since we are possibly resubscribing to the same topic we force the unsubscribe first.
		// Otherwide we redundantly subscribe and then unsubscribe
		subscription = nil
		subscription = mqtt.subscribe(topics: [("Test/#", .atMostOnce)]) { status in
			print("\(Date.nowInSeconds()) subAll0: \(status)")
		}
	}
	
	@IBAction func unsubscribePressed(_ sender: Any) {
		subscription = nil
	}
	
}

extension HelloWorldViewController {
	func mqtt(connected: MQTTConnectedState) {
		switch connected {
		case .started:
			statusTextField.stringValue = "Starting..."
			break
		case .connected(_):
			statusTextField.stringValue = "Connected"
			connectDisconnectButton.title = "Disconnect"
			break
		case .pinged(let status):
			switch status {
			case .notConnected:
				statusTextField.stringValue = "Not Connected"
				break
			case .sent:
				statusTextField.stringValue = "Pinging..."
				break
			case .skipped:
				break
			case .ack:
				statusTextField.stringValue = "Ping acknowledged!"
				break
			case .serverDied:
				statusTextField.stringValue = "Server Died"
				connectDisconnectButton.title = "Connect"
				break
			}
			break
		case .retry(_, _, _, _):
			statusTextField.stringValue = "Retrying..."
			break
		case .retriesFailed(_, _, _):
			break
		case .discconnected(_, _):
			statusTextField.stringValue = "Disconnected"
			connectDisconnectButton.title = "Connect"
			break
		}
	}
}
