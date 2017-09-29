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
		
	}
	
	func applicationDidBecomeActive(_ notification: Notification)
	{
		if(helloWorldView == nil)
		{
			NSApp.activate(ignoringOtherApps: true)
			
			//Setup the AppController
			controller = AppController()
			controller.delegate = self
			
			//Get the required view controller
			helloWorldView = NSApplication.shared.mainWindow!.contentViewController as! HelloWorldViewController
			
			let scoped = controller.mqtt.createBridge(subPath: "mac.test")
			
			helloWorldView.mqtt = scoped
			helloWorldView.mqttControl = controller.mqtt
		}
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		controller.goBackground()
	}

}

extension AppDelegate: AppControllerDelegate {
	func on(log: String) {
		print(log)
		helloWorldView.onLog(log)
	}
	
	func on(connected: MQTTConnectedState) {
		self.helloWorldView.mqtt(connected: connected)
	}
}

