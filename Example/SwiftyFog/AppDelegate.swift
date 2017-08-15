//
//  AppDelegate.swift
//  SwiftyFog
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
	var jovepressSubscription: MQTTSubscription?
	
	var registration: MQTTRegistration?
	var subscription: MQTTSubscription?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.

		mqtt = MQTTClient(
			client: MQTTClientParams(clientID: "SwiftyFogExample"),
			//host: MQTTHostParams(host: "thejoveexpress.local"),
			reconnect: MQTTReconnectParams())
		mqtt.delegate = self
		//mqtt?.debugPackageBytes = {print($0)}
		
		(self.window!.rootViewController as! ViewController).mqtt = mqtt
		
		jovepressSubscription = mqtt.subscribe(topics: ["thejoveexpress/#" : .atMostOnce])
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
		mqtt.publish(MQTTPubMsg(topic: "Bobs/Store/1", qos: .atMostOnce)) { (success) in
			print("\(Date.nowInSeconds()) publishQos0: \(success)")
		}
	}
	
	@IBAction func publishQos1() {
		mqtt.publish(MQTTPubMsg(topic: "Bobs/Store/1", qos: .atLeastOnce)) { (success) in
			print("\(Date.nowInSeconds()) publishQos1: \(success)")
		}
	}
	
	@IBAction func publishQos2() {
		mqtt.publish(MQTTPubMsg(topic: "Bobs/Store/1", qos: .exactlyOnce)) { (success) in
			print("\(Date.nowInSeconds()) publishQos2: \(success)")
		}
	}
	
	@IBAction func subAll0() {
		subscription = mqtt.subscribe(topics: ["Bobs/#": .atMostOnce]) { (success) in
			print("\(Date.nowInSeconds()) subAll0: \(success)")
		}
	}
	
	@IBAction func subAll1() {
		subscription = mqtt.subscribe(topics: ["Bobs/#": .atLeastOnce]) { (success) in
			print("\(Date.nowInSeconds()) subAll1: \(success)")
		}
	}
	
	@IBAction func subAll2() {
		subscription = mqtt.subscribe(topics: ["Bobs/#": .exactlyOnce]) { (success) in
			print("\(Date.nowInSeconds()) subAll2: \(success)")
		}
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
	func mqttConnectAttempted(client: MQTTClient) {
		print("\(Date.nowInSeconds()) MQTT Connection Attempt")
	}
	
	func mqttConnected(client: MQTTClient) {
		print("\(Date.nowInSeconds()) MQTT Connected")
		DispatchQueue.main.async {
			(self.window!.rootViewController as! ViewController).connected()
		}
	}
	
	func mqttPinged(client: MQTTClient, status: MQTTPingStatus) {
		print("\(Date.nowInSeconds()) MQTT Ping \(status)")
	}
	
	func mqttSubscriptionChanged(client: MQTTClient, subscription: MQTTSubscription, status: MQTTSubscriptionStatus) {
		print("\(Date.nowInSeconds()) MQTT Subscription \(subscription) \(status)")
		if status == .subscribed {
			print("    \(subscription.topics)")
		}
	}
	
	func mqttDisconnected(client: MQTTClient, reason: MQTTConnectionDisconnect, error: Error?) {
		print("\(Date.nowInSeconds()) MQTT Discconnected \(reason) \(error?.localizedDescription ?? "")")
		DispatchQueue.main.async {
			(self.window!.rootViewController as! ViewController).disconnected()
		}
	}
}

