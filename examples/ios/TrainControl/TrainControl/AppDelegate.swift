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
	var controller: MQTTMultiClientAppController!
	
	var trainControl: TrainViewController!
	//var logView: LogViewController!

	internal func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
	
		UserDefaults.standard.loadDefaults()
		NotificationCenter.default.addObserver(self, selector: #selector(settingChanged(notification:)), name: UserDefaults.didChangeNotification, object: nil)
		
		let clientID = UserDefaults.standard.string(forKey: "clientid_preference")!
		var client = MQTTClientParams(clientID: clientID)
		client.detectServerDeath = 2
		self.controller = MQTTMultiClientAppController(client: client, metrics: MQTTMetrics.verbose())
		self.trainControl = self.window!.rootViewController as? TrainViewController
		//self.logView = (tbc.viewControllers![1] as! LogViewController)
		
		self.controller.delegate = self
		
		// TODO: have train broadcast broker and remove the following line
		assignBroker(MQTTDiscoveredBroker(hostName: "joveexpress2.local"))
		controller.goForeground()
		return true
	}
	
	@objc func settingChanged(notification: NSNotification) {
	}
	
	func assignBroker(_ broker: MQTTDiscoveredBroker) {
		let brokerChanged = self.trainControl.mqttControl?.hostName != broker.hostName
		if brokerChanged {
			let client = self.controller.requestClient(broker: broker)
			client.start()
			self.trainControl.mqttControl = client
			self.trainControl.discoverBridge = client.createBridge(subPath: "train")
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

extension AppDelegate: MQTTMultiClientAppControllerDelegate {
	func discovered(mqttBrokers: [MQTTDiscoveredBroker]) {
		if !self.trainControl.mqttControl.connected {
			assignBroker(mqttBrokers[0])
		}
	}
	
	func on(mqttClient: (MQTTBridge & MQTTControl), log: String) {
		//logView.onLog(log)
	}

	func on(mqttClient: (MQTTBridge & MQTTControl), connected: MQTTConnectedState) {
		self.trainControl.mqtt(connected: connected)
	}
}
