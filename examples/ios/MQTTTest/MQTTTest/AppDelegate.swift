//
//  AppDelegate.swift
//  MQTTTest
//
//  Created by David Giovannini on 7/28/18.
//  Copyright © 2018 Object Computing Inc. All rights reserved.
//

import UIKit
import SwiftyFog_iOS

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	var window: UIWindow?
	var controller = MQTTClientAppController(metrics: MQTTMetrics.pedantic())
	
	var testing: TestingViewController!

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		self.testing = self.window!.rootViewController as? TestingViewController
		self.controller.mqttHost = "localhost"
		self.controller.delegate = self
		self.testing.mqtt = controller.client
		return true
	}

	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		controller.goBackground()
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		controller.goForeground()
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}
}

extension AppDelegate: MQTTClientAppControllerDelegate {
	func on(mqttClient: (MQTTBridge & MQTTControl), log: String) {
		print(log)
	}

	func on(mqttClient: (MQTTBridge & MQTTControl), connected: MQTTConnectedState) {
		print(connected)
	}
}

