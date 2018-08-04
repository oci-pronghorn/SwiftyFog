//
//  AppDelegate.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/13/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import UIKit
import UserNotifications
import SwiftyFog_iOS

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	var window: UIWindow?
	var controller = MQTTClientAppController(metrics: MQTTMetrics.verbose())
	
	var trainControl: TrainViewController!
	//var logView: LogViewController!

	internal func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
	
		self.trainControl = self.window!.rootViewController as? TrainViewController
		//self.logView = (tbc.viewControllers![1] as! LogViewController)
		
		self.controller.delegate = self
		
		UserDefaults.standard.loadDefaults()
		NotificationCenter.default.addObserver(self, selector: #selector(settingChanged(notification:)), name: UserDefaults.didChangeNotification, object: nil)
		
		assignBroker()
		return true
	}
	
	@objc func settingChanged(notification: NSNotification) {
		assignBroker()
	}
	
	func assignBroker() {
		let newBrokerHost = UserDefaults.standard.string(forKey: "broker_host_preference")!
		let brokerChanged = self.controller.mqttHost != newBrokerHost
		if brokerChanged {
			self.controller.mqttHost = newBrokerHost
			self.trainControl.mqttControl = controller.client
			self.trainControl.discoverBridge = controller.client
		}
	}
	
	@IBAction func gotoSettings(sender: Any?) {
		let settingsUrl = URL(string: UIApplication.openSettingsURLString)!
		UIApplication.shared.open(settingsUrl)
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
		NotificationCenter.default.removeObserver(self, name: UserDefaults.didChangeNotification, object: nil)
	}
}

extension AppDelegate: MQTTClientAppControllerDelegate {
	func on(mqttClient: (MQTTBridge & MQTTControl), log: String) {
		//logView.onLog(log)
	}

	func on(mqttClient: (MQTTBridge & MQTTControl), connected: MQTTConnectedState) {
		self.trainControl.mqtt(connected: connected)
	}
}
