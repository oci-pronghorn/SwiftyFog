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
	var controller: MqttClientAppController!
	
	var testing: TestingViewController!
	var trainControl: TrainViewController!
	var logView: LogViewController!

	internal func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
	
		let tbc = self.window!.rootViewController as! UITabBarController
		self.testing = (tbc.viewControllers![1] as! TestingViewController)
		self.trainControl = (tbc.viewControllers![0] as! TrainViewController)
		self.logView = (tbc.viewControllers![2] as! LogViewController)
		
		UserDefaults.standard.loadDefaults()
		NotificationCenter.default.addObserver(self, selector: #selector(settingChanged(notification:)), name: UserDefaults.didChangeNotification, object: nil)
		
		assignBroker()
		return true
	}
	
	@objc func settingChanged(notification: NSNotification) {
		assignBroker()
	}
	
	// This belong somewhere else
	var trainName: String = ""
	
	func assignBroker() {
		let newBrokerHost = UserDefaults.standard.string(forKey: "broker_host_preference")!
		var brokerChanged = self.controller == nil || (self.controller?.mqttHost ?? "") != newBrokerHost
		if brokerChanged {
			// TODO: We currently have a crashing bug tearing down an existing controller. It is likely recent reference rule changes with deinits
			self.controller.assign(MqttClientAppController(mqttHost: newBrokerHost))
			self.controller.delegate = self
			
			self.testing.mqtt = controller.mqtt
			brokerChanged = true
		}
		
		let newTrainName = UserDefaults.standard.string(forKey: "train_name_preference")!
		if newTrainName != trainName || brokerChanged {
			let scoped = controller.mqtt.createBridge(subPath: newTrainName)
			trainName = newTrainName
			self.trainControl.mqtt = scoped
			self.trainControl.mqttControl = controller.mqtt
		}
		
		if brokerChanged {
			controller.goForeground()
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

extension AppDelegate: MqttClientAppControllerDelegate {
	func on(log: String) {
		logView.onLog(log)
	}

	func on(connected: MQTTConnectedState) {
		self.trainControl.mqtt(connected: connected)
	}
}
