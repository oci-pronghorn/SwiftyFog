//
//  AppDelegate.swift
//  Thermometer
//
//  Created by Tobias Schweiger on 9/27/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Cocoa
import SwiftyFog_mac

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
	var controller: ThermoAppController!
	var helloWorldView : HelloWorldViewController!

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		//Setup the AppController
		controller = ThermoAppController()
		controller.delegate = self

		helloWorldView = NSApplication.shared.mainWindow!.contentViewController as? HelloWorldViewController
			
		helloWorldView.mqtt = controller.mqtt
		
		controller.start()
	}
	
	func applicationDidBecomeActive(_ notification: Notification) {
		// invoked before applicationDidFinishLaunching
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		controller.stop()
	}
}

extension AppDelegate: ThermoAppControllerDelegate {
	func on(log: String) {
		print(log)
		helloWorldView.onLog(log)
	}
	
	func on(connected: MQTTConnectedState) {
		self.helloWorldView.mqtt(connected: connected)
	}
}

