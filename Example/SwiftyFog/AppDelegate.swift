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
		
		trainSelect = (self.window!.rootViewController as! UITabBarController).viewControllers![1] as! TrainSelectViewController
		trainControl = (self.window!.rootViewController as! UITabBarController).viewControllers![0] as! TrainViewController

		// Select the train
		let trainName = "thejoveexpress"

		// Create the concrete MQTTClient to connect to a specific broker
		// MQTTClient is an MSTTBridge
		mqtt = MQTTClient(
			host: MQTTHostParams(host: trainName + ".local", port: .standard),
			auth: MQTTAuthentication(username: "dsjove", password: "password"),
			reconnect: MQTTReconnectParams())
		mqtt.delegate = self
		
		// We can add more debugging to look at the binary data moving in and out
		//mqtt.debugOut = {print($0)}
		
		// This view controller is specific to a train topic
		// Create an MSTTBridge specific to the selected train
		trainSelect.mqtt = mqtt
		let scoped = mqtt.createBridge(subPath: trainName)
		trainControl.mqtt = scoped
		
		// We want to start the process right away
		startConnecting()
		
		return true
	}

	@IBAction func startConnecting() {
		wantConnection = true
		mqtt.start()
	}

	@IBAction func stopConnecting() {
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
	func mqtt(client: MQTTClient, connected: MQTTConnectedState) {
		switch connected {
			case .connected(let counter):
				print("\(Date.nowInSeconds()) MQTT Connected \(counter)")
				DispatchQueue.main.async {
					self.trainControl.connected()
				}
				break
			case .retry(let rescus, let attempt, _):
				print("\(Date.nowInSeconds()) MQTT Connection Attempt \(rescus).\(attempt)")
				break
			case .discconnected(let reason, let error):
				print("\(Date.nowInSeconds()) MQTT Discconnected \(reason) \(error?.localizedDescription ?? "")")
				DispatchQueue.main.async {
					self.trainControl.disconnected()
				}
				break
		}
	}
	
	func mqtt(client: MQTTClient, pinged: MQTTPingStatus) {
		print("\(Date.nowInSeconds()) MQTT Ping \(pinged)")
	}
	
	func mqtt(client: MQTTClient, subscription: MQTTSubscriptionDetail, changed: MQTTSubscriptionStatus) {
		//print("\(Date.nowInSeconds()) MQTT Subscription \(subscription) \(changed)")
		if changed == .subscribed {
			print("    \(subscription.topics)")
		}
	}
	
	func mqtt(client: MQTTClient, unhandledMessage: MQTTMessage) {
		print("\(Date.nowInSeconds()) MQTT unhandled \(unhandledMessage)")
	}
}

