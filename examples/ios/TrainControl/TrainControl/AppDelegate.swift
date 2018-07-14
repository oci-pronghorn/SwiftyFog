//
//  AppDelegate.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/13/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import UIKit
import SwiftyFog_iOS

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	var window: UIWindow?
	var controller: MqttClientAppController!
	
	var testing: TestingViewController!
	var trainControl: TrainViewController!
	var logView: LogViewController!

	internal func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		
		let tbc = self.window!.rootViewController as! UITabBarController
		self.testing = (tbc.viewControllers![1] as! TestingViewController)
		self.trainControl = (tbc.viewControllers![0] as! TrainViewController)
		self.logView = (tbc.viewControllers![2] as! LogViewController)
		
		// Select the train
		let trainName = "thejoveexpress"

		controller = MqttClientAppController(mqttHost: trainName + ".local")
		controller.delegate = self
		
		testing.mqtt = controller.mqtt
		
		// This view controller is specific to a train topic
		// Create an MQTTBridge specific to the selected train
		let scoped = controller.mqtt.createBridge(subPath: trainName)
		trainControl.mqtt = scoped
		trainControl.mqttControl = controller.mqtt
		
		// Start up the client
		controller.goForeground()
		
		return true
	}

	func applicationWillResignActive(_ application: UIApplication) {
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		controller.goBackground()
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		controller.goForeground()
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
	}

	func applicationWillTerminate(_ application: UIApplication) {
	}
}

extension AppDelegate: MqttClientAppControllerDelegate {
	func on(log: String) {
		logView.onLog(log)
	}

	func on(connected: MQTTConnectedState) {
		self.trainControl.mqtt(connected: connected)
	}
}
