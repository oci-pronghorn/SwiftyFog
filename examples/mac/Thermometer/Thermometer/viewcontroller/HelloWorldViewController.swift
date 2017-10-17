//
//  ViewController.swift
//  Thermometer
//
//  Created by Tobias Schweiger on 9/27/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Cocoa
import SwiftyFog_mac

public extension NSSlider {
	public var rational: FogRational<Int64> {
		get {
			let numerator = NSNumber(value: self.intValue).int64Value
			let denominator = NSNumber( value: self.maxValue).int64Value
			
			return FogRational(num: numerator, den: denominator)
		}
		set {
			self.intValue = Int32(Float(self.maxValue) * Float(newValue.num) / Float(newValue.den))
		}
	}
}

class HelloWorldViewController : NSViewController {
	
	let thermometer = Thermometer()
	
	var mqtt: MQTTBridge! {
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
		DispatchQueue.main.async {
			let _ = self.view
			self.logTextView.textStorage?.append(NSAttributedString(string: "\(str)\n"))
			self.logTextView.scrollToEndOfDocument(self)
		}
	}
	
	@IBAction func connectDisconnectPressed(_ sender: Any) {
/*		if mqttControl.started {
			mqttControl.stop()
		}
		else {
			mqttControl.start()
		}*/
	}
	
	@IBAction func publishFirstTestPressed(_ sender: Any) {
		
	}
	
	@IBAction func subscribeAllPressed(_ sender: Any) {
		// Since we are possibly resubscribing to the same topic we force the unsubscribe first.
		// Otherwide we redundantly subscribe and then unsubscribe
		subscription = nil
		subscription = mqtt.subscribe(topics: [("temperature/#", .atMostOnce)]) { status in
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
		case .disconnected(_, _):
			statusTextField.stringValue = "Disconnected"
			connectDisconnectButton.title = "Connect"
			break
		}
	}
}

extension HelloWorldViewController {
	func feedbackCut() {
		thermometer.reset()
	}
	
	func assertValues() {
		thermometer.assertValues()
	}
	
	@IBAction func doTemperatureAdjustment(_ sender: NSSlider) {
		thermometer.control(temperature: sender.rational)
	}
	
}

extension HelloWorldViewController : ThermometerDelegate {
	func thermometer(temperature: FogRational<Int64>, _ asserted: Bool) {
		self.temperatureTextField.stringValue = "Temperature: \(temperature.num)"
	}
	
}
