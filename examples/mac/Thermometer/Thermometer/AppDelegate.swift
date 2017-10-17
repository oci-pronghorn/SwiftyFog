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
		
	}
	
	func applicationDidBecomeActive(_ notification: Notification)
	{
		//Setup the AppController
		if controller == nil {
			controller = ThermoAppController()
			controller.delegate = self
			controller.goForeground()
		}
		
		if(helloWorldView == nil)
		{
			NSApp.activate(ignoringOtherApps: true)

			//Get the required view controller
			helloWorldView = NSApplication.shared.mainWindow!.contentViewController as! HelloWorldViewController
			
			helloWorldView.mqtt = controller.mqtt
		}
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		controller.goBackground()
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

