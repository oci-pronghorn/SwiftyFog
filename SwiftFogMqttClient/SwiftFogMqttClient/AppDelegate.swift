//
//  AppDelegate.swift
//  SwiftFogMqttClient
//
//  Created by David Giovannini on 8/13/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import UIKit
import SwiftyFog

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?
	var mqtt: MQTTClient!
	var registration: MQTTRegistration?
	var subscription: MQTTSubscription?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		
		mqtt = MQTTClient(client: MQTTClientParams(clientID: "SwiftyFog"))
		mqtt.delegate = self
		
		registration = mqtt.registerTopic(path: "", action: receiveMessage)
		
		return true
	}
	
	@IBAction func connect() {
		mqtt.start()
	}
	
	@IBAction func cleanDisconnect() {
		mqtt.stop()
	}
	
	@IBAction func publishQos0() {
		mqtt.publish(pubMsg: MQTTPubMsg(topic: "Bobs/Store/1", qos: .atMostOnce), completion: { (success) in
			print("\(Date.nowInSeconds()) publishQos0: \(success)")
		})
	}
	
	@IBAction func publishQos1() {
		mqtt.publish(pubMsg: MQTTPubMsg(topic: "Bobs/Store/1", qos: .atLeastOnce), completion: { (success) in
			print("\(Date.nowInSeconds()) publishQos1: \(success)")
		})
	}
	
	@IBAction func publishQos2() {
		mqtt.publish(pubMsg: MQTTPubMsg(topic: "Bobs/Store/1", qos: .exactlyOnce), completion: { (success) in
			print("\(Date.nowInSeconds()) publishQos2: \(success)")
		})
	}
	
	@IBAction func subAll0() {
		subscription = mqtt.subscribe(topics: ["#": .atMostOnce], completion: { (success) in
			print("\(Date.nowInSeconds()) subAll0: \(success)")
		})
	}
	
	@IBAction func subAll1() {
		subscription = mqtt.subscribe(topics: ["#": .atLeastOnce], completion: { (success) in
			print("\(Date.nowInSeconds()) subAll1: \(success)")
		})
	}
	
	@IBAction func subAll2() {
		subscription = mqtt.subscribe(topics: ["#": .exactlyOnce], completion: { (success) in
			print("\(Date.nowInSeconds()) subAll2: \(success)")
		})
	}
	
	func receiveMessage(message: MQTTMessage) {
		print("\(Date.nowInSeconds()) \(message)")
	}
	
	@IBAction func unsubAll() {
		subscription = nil
	}

	func applicationWillResignActive(_ application: UIApplication) {
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
	}

	func applicationWillTerminate(_ application: UIApplication) {
	}
}

extension AppDelegate: MQTTClientDelegate {
	func mqttConnected(client: MQTTClient) {
		print("\(Date.nowInSeconds()) MQTT Connected")
	}
	
	func mqttPinged(client: MQTTClient, status: MQTTPingStatus) {
		print("\(Date.nowInSeconds()) MQTT Ping \(status)")
	}
	
	func mqttSubscriptionChanged(client: MQTTClient, subscription: MQTTSubscription, status: MQTTSubscriptionStatus) {
		print("\(Date.nowInSeconds()) MQTT Subscription \(subscription) \(status)")
	}
	
	func mqttDisconnected(client: MQTTClient, reason: MQTTConnectionDisconnect, error: Error?) {
		print("\(Date.nowInSeconds()) MQTT Discconnected \(reason) \(error?.localizedDescription ?? "")")
	}
}

