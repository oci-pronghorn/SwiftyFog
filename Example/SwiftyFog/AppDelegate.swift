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
	
	var wantConnection: Bool = false
	var subscription: MQTTSubscription?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		
		// Select the train
		let trainName = "thejoveexpress"

		// Create the concrete MQTTClient to connect to a specific broker
		// MQTTClient is an MSTTBridge
		mqtt = MQTTClient(
			host: MQTTHostParams(host: trainName + ".local"),
			reconnect: MQTTReconnectParams())
		mqtt.delegate = self
		
		// We can add more debugging to look at the binary data moving in and out
		//mqtt.debugOut = {print($0)}
		
		// This view controller is specific to a train topic
		// Create an MSTTBridge specific to the selected train
		let scoped = mqtt.createBridge(subPath: trainName)
		(self.window!.rootViewController as! TrainViewController).mqtt = scoped
		
		return true
	}

	func applicationWillResignActive(_ application: UIApplication) {
		// Be a good iOS citizen and shutdown the connection and timers
		mqtt.stop()
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// If want to be connected, restore it
		if wantConnection {
			mqtt.start()
		}
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Be a good MQTT citizen and issue the Disconnect message
		mqtt.stop()
	}
}

extension AppDelegate {
	@IBAction func connect() {
		wantConnection = true
		mqtt.start()
	}

	@IBAction func cleanDisconnect() {
		wantConnection = false
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
		// Since we are possibly resubscribing to the same topic we force the unsubscribe first.
		// Otherwide we redundantly subscribe and then unsubscribe
		subscription = nil
		subscription = mqtt.subscribe(topics: [("Bobs/#", .atMostOnce)]) { (success) in
			print("\(Date.nowInSeconds()) subAll0: \(success)")
		}
	}

	@IBAction func subAll1() {
		subscription = nil
		subscription = mqtt.subscribe(topics: [("Bobs/#", .atLeastOnce)]) { (success) in
			print("\(Date.nowInSeconds()) subAll1: \(success)")
		}
	}

	@IBAction func subAll2() {
		subscription = nil
		subscription = mqtt.subscribe(topics: [("Bobs/#", .exactlyOnce)]) { (success) in
			print("\(Date.nowInSeconds()) subAll2: \(success)")
		}
	}

	@IBAction func unsubAll() {
		// Setting scription (or registration) to nil (or reassign) will unsubscribe
		subscription = nil
	}
}

// The client will broadcast important events to the application
// can react appropriately. The invoking thread is not known.
extension AppDelegate: MQTTClientDelegate {
	func mqttConnectAttempted(client: MQTTClient) {
		print("\(Date.nowInSeconds()) MQTT Connection Attempt")
	}
	
	func mqttConnected(client: MQTTClient) {
		print("\(Date.nowInSeconds()) MQTT Connected")
		DispatchQueue.main.async {
			(self.window!.rootViewController as! TrainViewController).connected()
		}
	}
	
	func mqttPinged(client: MQTTClient, status: MQTTPingStatus) {
		print("\(Date.nowInSeconds()) MQTT Ping \(status)")
	}
	
	func mqttSubscriptionChanged(client: MQTTClient, subscription: MQTTSubscriptionDetail, status: MQTTSubscriptionStatus) {
		print("\(Date.nowInSeconds()) MQTT Subscription \(subscription) \(status)")
		if status == .subscribed {
			print("    \(subscription.topics)")
		}
	}
	
	func mqttDisconnected(client: MQTTClient, reason: MQTTConnectionDisconnect, error: Error?) {
		print("\(Date.nowInSeconds()) MQTT Discconnected \(reason) \(error?.localizedDescription ?? "")")
		DispatchQueue.main.async {
			(self.window!.rootViewController as! TrainViewController).disconnected()
		}
	}
	
	func mqttUnhandledMessage(message: MQTTMessage) {
		print("\(Date.nowInSeconds()) MQTT unhandled \(message)")
	}
}

