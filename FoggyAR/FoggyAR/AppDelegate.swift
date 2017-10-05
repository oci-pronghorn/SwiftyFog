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
	var controller: ARAppController!
	
	var trainARViewer: ARViewController!
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		
		trainARViewer = (self.window!.rootViewController) as! ARViewController
		
		// Select the train
		let trainName = "thejoveexpress"
		
		controller = ARAppController(trainName)
		
		// This view controller is specific to a train topic
		// Create an MQTTBridge specific to the selected train
		let scoped = controller.mqtt.createBridge(subPath: trainName)
		
		trainARViewer.mqtt = scoped
	
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
		controller.goForeground()
	}
	
	func applicationWillTerminate(_ application: UIApplication) {
		controller.goBackground()
	}
}
