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
	var controller: AppController!
	
	var trainSelect: TrainSelectViewController!
	var trainControl: TrainViewController!
	var logView: LogViewController!

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		
		trainSelect = (self.window!.rootViewController as! UITabBarController).viewControllers![1] as! TrainSelectViewController
		trainControl = (self.window!.rootViewController as! UITabBarController).viewControllers![0] as! TrainViewController
		logView = (self.window!.rootViewController as! UITabBarController).viewControllers![2] as! LogViewController
		
		// Select the train
		let trainName = "thejoveexpress"

		controller = AppController(trainName)
		controller.delegate = self
		
		// This view controller is specific to a train topic
		// Create an MQTTBridge specific to the selected train
		trainSelect.mqtt = controller.mqtt
		let scoped = controller.mqtt.createBridge(subPath: trainName)
		trainControl.mqtt = scoped
		trainControl.mqttControl = controller.mqtt
		
		return true
	}

	func applicationWillResignActive(_ application: UIApplication) {
		controller.goBackground()
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		controller.goForeground()
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
	}

	func applicationWillTerminate(_ application: UIApplication) {
		controller.goBackground()
	}
}

extension AppDelegate: AppControllerDelegate {
	func on(log: String) {
		logView.onLog(log)
	}

	func on(connected: MQTTConnectedState) {
		self.trainControl.mqtt(connected: connected)
	}
}

