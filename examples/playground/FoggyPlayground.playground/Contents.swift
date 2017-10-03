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

// All connection events are optioanlly broadcasted from the client
// given a delegate
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

// Start up the default client ("localhost")
let delegate = Delegate()

let metrics = MQTTMetrics(prefix: {"\(Date.nowInSeconds()) MQTT "})
metrics.debugOut = {print($0)}
metrics.doPrintSendPackets = true
metrics.doPrintReceivePackets = true

let mqtt = MQTTClient(metrics: metrics)


mqtt.delegate = delegate
mqtt.start()

// Create our business logic
// TODO: Why are this prints not being made.
class Business {
	let subscription = mqtt.broadcast(to: business, topics: [
				("my/topic", .atMostOnce, Business.receive),
			]) { listener, state in
				print("Subscription completion" )
			}
	
	func receive(_ msg: MQTTMessage) {
		print("Received \(msg.topic)")
	}
}

let business = Business()
mqtt.publish(MQTTMessage(topic: "my/topic"))

