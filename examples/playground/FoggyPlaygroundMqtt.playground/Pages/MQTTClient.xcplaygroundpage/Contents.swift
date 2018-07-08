/*
	Welcome to FoggyPlayground!
	This playground introduces you to the basics of FoggySwift, a Swift library for MQTT.

  	Install Mosquitto on your Mac
  	https://mosquitto.org/download/

  	Be certain to build SwiftyFog_iOS for simulator on making changes to the library.
*/

import UIKit
import PlaygroundSupport
import SwiftyFog_iOS

// All connection events are optioanlly broadcasted from the client given a delegate
class Delegate: MQTTClientDelegate {
	func mqtt(client: MQTTClient, connected: MQTTConnectedState) {
		switch connected {
		case .started:
			print("* Started")
			break
		case .connected(_, _, _, let counter):
			print("* Connected \(counter)")
			break
		case .pinged(let status):
			print("* Ping \(status)")
			break
		case .retry(_, let rescus, let attempt, _):
			print("* Connection Attempt \(rescus).\(attempt)")
			break
		case .retriesFailed(let counter, let rescus, _):
			print("* Connection Failed \(counter).\(rescus)")
			break
		case .disconnected(_, let reason, let error):
			print("* Discconnected \(reason) \(error?.localizedDescription ?? "")")
			break
		}
	}
	
	func mqtt(client: MQTTClient, unhandledMessage: MQTTMessage) {
		print("* Unhandled \(unhandledMessage)")
	}
	
	func mqtt(client: MQTTClient, recreatedSubscriptions: [MQTTSubscription]) {
	}
}

// Keep page alive beyond linear execution
PlaygroundPage.current.needsIndefiniteExecution = true

// Add some optional debug output
let metrics = MQTTMetrics()
metrics.debugOut = {print("- \($0)")}
metrics.doPrintSendPackets = true
metrics.doPrintReceivePackets = true

// Start up the default client - "localhost"
let mqtt = MQTTClient(metrics: metrics)
let delegate = Delegate()
mqtt.delegate = delegate
mqtt.start()

// Create our business logic
class Business {
	private var subscription: MQTTBroadcaster?
	
	var mqtt: MQTTBridge? {
		didSet {
			// Create the subscription
			self.subscription = mqtt?.broadcast(to: self, topics: [
				("my/topic", .atMostOnce, Business.receive),
			]) { listener, state in
				print("+ Subscription: \(state)" )
			}
		}
	}
	
	func send() {
		let value: Int = 42
		let topic = "my/topic"
		var payload = Data()
		payload.fogAppend(42)
		print("+ Sending \(topic) \(value)")
		mqtt?.publish(MQTTMessage(topic: topic, payload: payload))
	}
	
	private func receive(_ msg: MQTTMessage) {
		let value: Int = msg.payload.fogExtract()
		print("+ Received \(msg.topic) \(value)")
		print("+ Metrics\n\(metrics)")
		// Exit page when payload received
		PlaygroundPage.current.finishExecution()
	}
}

let business = Business()
business.mqtt = mqtt
business.send()
