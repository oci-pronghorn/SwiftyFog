/*
	Welcome to FoggyPlayground!
	This playground introduces you to the basics of FoggySwift, a Swift library for MQTT.

  	Install Mosquitto on your Mac
  	https://mosquitto.org/download/
*/

import UIKit
import PlaygroundSupport
import SwiftyFog_iOS

PlaygroundPage.current.needsIndefiniteExecution = true

class Delegate: MQTTClientDelegate {
	func mqtt(client: MQTTClient, connected: MQTTConnectedState) {
		switch connected {
		case .started:
			print("Started")
			break
		case .connected(let counter):
			print("Connected \(counter)")
			break
		case .pinged(let status):
			print("Ping \(status)")
			break
		case .retry(_, let rescus, let attempt, _):
			print("Connection Attempt \(rescus).\(attempt)")
			break
		case .retriesFailed(let counter, let rescus, _):
			print("Connection Failed \(counter).\(rescus)")
			break
		case .discconnected(let reason, let error):
			print("Discconnected \(reason) \(error?.localizedDescription ?? "")")
			break
		}
	}
	
	func mqtt(client: MQTTClient, unhandledMessage: MQTTMessage) {
		print("Unhandled \(unhandledMessage)")
	}
	
	func mqtt(client: MQTTClient, recreatedSubscriptions: [MQTTSubscription]) {
	}
}

let delegate = Delegate()
let mqtt = MQTTClient()
mqtt.delegate = delegate
mqtt.start()

