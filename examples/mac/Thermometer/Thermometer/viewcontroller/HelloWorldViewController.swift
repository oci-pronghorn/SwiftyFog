//
//  ViewController.swift
//  Thermometer
//
//  Created by Tobias Schweiger on 9/27/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Cocoa
import SwiftyFog_mac

class HelloWorldViewController : NSViewController {
	let thermometer = Thermometer()
	
	var mqtt: (MQTTBridge & MQTTControl)! {
		didSet {
			thermometer.delegate = self
			thermometer.mqtt = mqtt
		}
	}
	var subscription: MQTTSubscription?
	
	@IBOutlet weak var statusTextField: NSTextField!
	@IBOutlet var logTextView: NSTextView!
	@IBOutlet weak var connectDisconnectButton: NSButton!
	@IBOutlet weak var temperatureSlider: NSSlider!
	@IBOutlet weak var temperatureTextField: NSTextField!
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	func onLog(_ str: String) {
		let _ = self.view
		self.logTextView.textStorage?.append(NSAttributedString(string: "\(str)\n"))
		self.logTextView.scrollToEndOfDocument(self)
	}
	
	@IBAction func connectDisconnectPressed(_ sender: Any) {
		if mqtt.started {
			mqtt.stop()
		}
		else {
			mqtt.start()
		}
	}
	
	@IBAction func subscribeAllPressed(_ sender: Any) {
		// Since we are resubscribing to the same topic we force the unsubscribe first.
		// Otherwide we redundantly subscribe and then unsubscribe.
		subscription = nil
		subscription = mqtt.subscribe(topics: [("temperature/#", .atMostOnce)]) { status in
			print("\(Date.nowInSeconds()) subAll0: \(status)")
		}
	}
	
	@IBAction func unsubscribePressed(_ sender: Any) {
		subscription = nil
	}
	
	@IBAction func doTemperatureAdjustment(_ sender: NSSlider) {
		// force a temperature through to test
		var data = Data()
		data.fogAppend(Int32(temperatureSlider.intValue))
		mqtt.publish(MQTTMessage(topic: "temperature/feedback", payload: data))
	}
}

extension HelloWorldViewController {
	func mqtt(connected: MQTTConnectedState) {
		switch connected {
		case .started:
			self.statusTextField.stringValue = "Starting..."
			break
		case .connected:
			self.statusTextField.stringValue = "Connected"
			self.connectDisconnectButton.title = "Disconnect"
			break
		case .pinged(let status):
			switch status {
			case .notConnected:
				self.statusTextField.stringValue = "Not Connected"
				break
			case .sent:
				self.statusTextField.stringValue = "Pinging..."
				break
			case .skipped:
				break
			case .ack:
				self.statusTextField.stringValue = "Ping acknowledged!"
				break
			case .serverDied:
				self.statusTextField.stringValue = "Server Died"
				self.connectDisconnectButton.title = "Connect"
				break
			}
			break
		case .retry:
			self.statusTextField.stringValue = "Retrying..."
			break
		case .retriesFailed:
			break
		case .disconnected:
			self.statusTextField.stringValue = "Disconnected"
			self.connectDisconnectButton.title = "Connect"
			break
		}
	}
}

extension HelloWorldViewController : ThermometerDelegate {
	func thermometer(temperature: Int32) {
		self.temperatureTextField.stringValue = "Temperature: \(temperature)"
	}
}
