//
//  ViewController.swift
//  Example_MacOS
//
//  Created by Tobias Schweiger on 9/27/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Cocoa
import SwiftyFog_Mac

class HelloWorldViewController : NSViewController {
	
	var mqtt: MQTTBridge!
	var subscription: MQTTSubscription?

	override func viewDidLoad() {
		super.viewDidLoad()

		// Do any additional setup after loading the view.
	}

	@IBAction func connectButtonPressed(_ sender: Any) {
		print("pressed!")
	}
	
	override var representedObject: Any? {
		didSet {
		// Update the view, if already loaded.
		}
	}


}

