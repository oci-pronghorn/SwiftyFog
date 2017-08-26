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
	var metrics: MQTTMetrics?
	var wantConnection: Bool = false
	
	var trainSelect: TrainSelectViewController!
	var trainControl: TrainViewController!

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		
		trainSelect = (self.window!.rootViewController as! UITabBarController).viewControllers![0] as! TrainSelectViewController
		trainControl = (self.window!.rootViewController as! UITabBarController).viewControllers![1] as! TrainViewController

		// Select the train
		let trainName = "thejoveexpress"
		
		// Setup metrics
		metrics = MQTTMetrics(prefix: {"\(Date.nowInSeconds()) MQTT: "})
		//metrics?.debugOut = {print($0)}
		metrics?.consoleOut = {print($0)}

		// Create the concrete MQTTClient to connect to a specific broker
		// MQTTClient is an MQTTBridge
		mqtt = MQTTClient(
			host: MQTTHostParams(host: trainName + ".local", port: .standard),
			auth: MQTTAuthentication(username: "dsjove", password: "password"),
			reconnect: MQTTReconnectParams(),
			metrics: metrics)
		mqtt.delegate = self
		
		// This view controller is specific to a train topic
		// Create an MSTTBridge specific to the selected train
		trainSelect.mqtt = mqtt
		let scoped = mqtt.createBridge(subPath: trainName)
		trainControl.mqtt = scoped
		
		// We want to start the process right away
		connect()
		
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
	func mqtt(client: MQTTClient, connected: MQTTConnectedState) {
		switch connected {
			case .connected(let counter):
				metrics?.print("Connected \(counter)")
				DispatchQueue.main.async {
					self.trainControl.connected()
				}
				break
			case .retry(let attempt, let rescus, let spec):
				metrics?.print("Connection Attempt \(rescus).\(attempt) of \(spec.retryCount)")
				break
			case .discconnected(let reason, let error):
				print("Discconnected \(reason) \(error?.localizedDescription ?? "")")
				DispatchQueue.main.async {
					self.trainControl.disconnected()
				}
				break
		}
	}
	
	func mqtt(client: MQTTClient, pinged: MQTTPingStatus) {
		metrics?.debug("Ping \(pinged)")
	}
	
	func mqtt(client: MQTTClient, subscription: MQTTSubscriptionDetail, changed: MQTTSubscriptionStatus) {
		metrics?.debug("Subscription \(subscription) \(changed)")
		if changed == .subscribed {
			metrics?.debug("    \(subscription.topics)")
		}
	}
	
	func mqtt(client: MQTTClient, unhandledMessage: MQTTMessage) {
		metrics?.print("Unhandled \(unhandledMessage)")
	}
}

