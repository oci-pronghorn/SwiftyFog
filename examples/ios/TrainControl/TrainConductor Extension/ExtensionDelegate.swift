//
//  ExtensionDelegate.swift
//  TrainConductor Extension
//
//  Created by David Giovannini on 7/7/18.
//  Copyright © 2018 Object Computing Inc. All rights reserved.
//

import WatchKit
import SwiftFog_watch

class ExtensionDelegate: NSObject, WKExtensionDelegate {
	var controller = MQTTClientAppController()

    func applicationDidFinishLaunching() {
		controller.delegate = self
		
		UserDefaults.standard.loadDefaults()
		NotificationCenter.default.addObserver(self, selector: #selector(settingChanged(notification:)), name: UserDefaults.didChangeNotification, object: nil)
		
		assignBroker()
    }
	
	@objc func settingChanged(notification: NSNotification) {
		assignBroker()
	}
	
	func assignBroker() {
		let newBrokerHost = UserDefaults.standard.string(forKey: "broker_host_preference")!
		let brokerChanged = self.controller.mqttHost != newBrokerHost
		if brokerChanged {
			self.controller.mqttHost = newBrokerHost
			TrainInterfaceController.set(discoverBridge: controller.client!, mqttControl: controller.client)
		}
	}

    func applicationDidBecomeActive() {
		controller.goForeground()
    }

    func applicationWillResignActive() {
		controller.goBackground()
    }
	

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
			if #available(watchOSApplicationExtension 5.0, *) {
				switch task {
				case let backgroundTask as WKApplicationRefreshBackgroundTask:
					// Be sure to complete the background task once you’re done.
					backgroundTask.setTaskCompletedWithSnapshot(false)
				case let snapshotTask as WKSnapshotRefreshBackgroundTask:
					// Snapshot tasks have a unique completion call, make sure to set your expiration date
					snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
				case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
					// Be sure to complete the connectivity task once you’re done.
					connectivityTask.setTaskCompletedWithSnapshot(false)
				case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
					// Be sure to complete the URL session task once you’re done.
					urlSessionTask.setTaskCompletedWithSnapshot(false)
				case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
					// Be sure to complete the relevant-shortcut task once you're done.
					relevantShortcutTask.setTaskCompletedWithSnapshot(false)
				case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
					// Be sure to complete the intent-did-run task once you're done.
					intentDidRunTask.setTaskCompletedWithSnapshot(false)
				default:
					// make sure to complete unhandled task types
					task.setTaskCompletedWithSnapshot(false)
				}
			} else {
				// Fallback on earlier versions
			}
        }
    }
}

extension ExtensionDelegate: MQTTClientAppControllerDelegate {
	func on(mqttClient: (MQTTBridge & MQTTControl), log: String) {
		print(log)
	}
	
	func on(mqttClient: (MQTTBridge & MQTTControl), connected: MQTTConnectedState) {
		(WKExtension.shared().rootInterfaceController as! TrainInterfaceController).mqtt(connected: connected)
	}
}
