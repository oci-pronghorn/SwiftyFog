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

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		
		controller = AppController()
		controller.delegate = self as? AppControllerDelegate
		
		helloWorldView = 
		
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}


}

