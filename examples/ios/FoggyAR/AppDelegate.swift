//
//  AppDelegate.swift
//  FoggyAR
//
//  Created by Tobias Schweiger on 10/4/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import UIKit
import SwiftyFog_iOS

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	var window: UIWindow?
	var controller: FoggyAppController!
	
	var trainARViewer: FoggyViewController!
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		
		trainARViewer = (self.window!.rootViewController) as! FoggyViewController
		
		// Select the train
		let trainName = "thejoveexpress"
		
		controller = FoggyAppController(trainName)
		
		// This view controller is specific to a train topic
		// Create an MQTTBridge specific to the selected train
		let scoped = controller.mqtt.createBridge(subPath: trainName)
		
		trainARViewer.mqtt = scoped
		controller.delegate = self
		
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

extension AppDelegate: FoggyAppControllerDelegate {
	func on(log: String) {
	}
	
	func on(connected: MQTTConnectedState) {
		self.trainARViewer.mqtt(connected: connected)
	}
}
