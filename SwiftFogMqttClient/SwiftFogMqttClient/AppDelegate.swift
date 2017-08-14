//
//  AppDelegate.swift
//  SwiftFogMqttClient
//
//  Created by David Giovannini on 8/13/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import UIKit
import SwiftyFog

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?
	var mqtt: MQTTClient?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		mqtt = MQTTClient()
		mqtt?.start()
		return true
	}
	
	@IBAction func cleanDisconnect() {
		mqtt?.stop()
	}
	
	@IBAction func publishQos0() {
		mqtt?.publish(pubMsg: MQTTPubMsg(topic: "Bobs/Store/1", qos: .atMostOnce), completion: { (success) in
			print(success)
		})
	}
	
	@IBAction func publishQos1() {
		mqtt?.publish(pubMsg: MQTTPubMsg(topic: "Bobs/Store/1", qos: .atLeastOnce), completion: { (success) in
			print(success)
		})
	}
	
	@IBAction func publishQos2() {
		mqtt?.publish(pubMsg: MQTTPubMsg(topic: "Bobs/Store/1", qos: .exactlyOnce), completion: { (success) in
			print(success)
		})
	}
	
	var sub: MQTTSubscription?
	
	@IBAction func subAll0() {
		sub = mqtt?.subscribe(topics: ["#": .atMostOnce], completion: { (success) in
			print(success)
		})
	}
	
	@IBAction func subAll1() {
		sub = mqtt?.subscribe(topics: ["#": .atLeastOnce], completion: { (success) in
			print(success)
		})
	}
	
	@IBAction func subAll2() {
		sub = mqtt?.subscribe(topics: ["#": .exactlyOnce], completion: { (success) in
			print(success)
		})
	}
	
	@IBAction func unsubAll() {
		sub = nil
	}

	func applicationWillResignActive(_ application: UIApplication) {
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
	}

	func applicationWillTerminate(_ application: UIApplication) {
	}
}

