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
	
	var trainSelect: TrainSelectViewController!
	var trainControl: TrainViewController!

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		
		trainSelect = (self.window!.rootViewController as! UITabBarController).viewControllers![0] as! TrainSelectViewController
		trainControl = (self.window!.rootViewController as! UITabBarController).viewControllers![1] as! TrainViewController

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
		trainSelect.mqtt = mqtt
		let scoped = mqtt.createBridge(subPath: trainName)
		trainControl.mqtt = scoped
		
		return true
	}

	@IBAction func connect() {
		wantConnection = true
		mqtt.start()
	}

	@IBAction func cleanDisconnect() {
		wantConnection = false
		mqtt.stop()
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

// The client will broadcast important events to the application
// can react appropriately. The invoking thread is not known.
extension AppDelegate: MQTTClientDelegate {
	func mqttConnectAttempted(client: MQTTClient) {
		print("\(Date.nowInSeconds()) MQTT Connection Attempt")
	}
	
	func mqttConnected(client: MQTTClient) {
		print("\(Date.nowInSeconds()) MQTT Connected")
		DispatchQueue.main.async {
			self.trainControl.connected()
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
			self.trainControl.disconnected()
		}
	}
	
	func mqttUnhandledMessage(message: MQTTMessage) {
		print("\(Date.nowInSeconds()) MQTT unhandled \(message)")
	}
}

