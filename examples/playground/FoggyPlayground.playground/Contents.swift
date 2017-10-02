/*
	Welcome to FoggyPlayground!
	This playground attempts to introduce you to the basics of
  FoggySwift, a Swift library for MQTT.
*/

import UIKit
import SwiftyFog_iOS

import PlaygroundSupport

//TODO: Get rid of AppController
let controller : AppController = AppController(username: "test", password: "password")

var mqttControl: MQTTControl! {
	didSet {
		mqttControl.start()
		print("Started the MQTT controller!")
	}
}

var mqtt: MQTTBridge!
var subscription: MQTTSubscription?
