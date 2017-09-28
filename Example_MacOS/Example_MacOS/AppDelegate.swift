//
//  AppDelegate.swift
//  Example_MacOS
//
//  Created by Tobias Schweiger on 9/27/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Cocoa
import SwiftyFog_Mac

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
	var controller: AppController!
	
	var helloWorldView : HelloWorldViewController!

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		
		controller = AppController()
		controller.delegate = self
	
		helloWorldView = NSApplication.shared.mainWindow!.contentViewController as! HelloWorldViewController

		let scoped = controller.mqtt.createBridge(subPath: "HelloWorld")
		
		helloWorldView.mqtt = scoped
		helloWorldView.mqttControl = controller.mqtt
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		controller.goBackground()
	}

}

extension AppDelegate: AppControllerDelegate {
	func on(log: String) {
		print(log)
	}
	
	func on(connected: MQTTConnectedState) {
		self.helloWorldView.mqtt(connected: connected)
	}
}

