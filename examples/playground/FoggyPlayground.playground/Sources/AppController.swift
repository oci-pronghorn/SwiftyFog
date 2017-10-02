import Foundation
import SwiftyFog

public class AppController {
	var mqtt: (MQTTBridge & MQTTControl)!
	var metrics: MQTTMetrics?
	var wasStarted: Bool = false
	
	public init(username : String, password : String) {
		
		// Setup metrics
		metrics = MQTTMetrics(prefix: {"\(Date.nowInSeconds()) MQTT "})
		metrics?.doPrintSendPackets = true
		metrics?.doPrintReceivePackets = true
		metrics?.doPrintWireData = true
		metrics?.debugOut = {print($0)}
		
		// Create the concrete MQTTClient to connect to a specific broker
		let client = MQTTClientParams()
		
		let mqtt = MQTTClient(
			client: client,
			host: MQTTHostParams(),
			auth: MQTTAuthentication(username: "tobischw", password: "password"),
			reconnect: MQTTReconnectParams(),
			metrics: metrics)
		
		print("Created MQTT client!")
		
		//mqtt.delegate = self
		
		self.mqtt = mqtt
		
	}
	
	public func goForeground() {
		// If it wants to be started, restore it
		if wasStarted {
			mqtt.start()
		}
	}
	
	public func goBackground() {
		// Be a good MacOS citizen and shutdown the connection and timers
		wasStarted = mqtt.started
		mqtt.stop()
	}
}

// The client will broadcast important events to the application
// can react appropriately. The invoking thread is not known.

/* TODO: reimplement this for playgrounds
extension AppController: MQTTClientDelegate {
	func mqtt(client: MQTTClient, connected: MQTTConnectedState) {
		let log: String
		switch connected {
		case .started:
			log = "Started"
			break
		case .connected(let counter):
			log = "Connected \(counter)"
			break
		case .pinged(let status):
			log = "Pinged \(status)"
			break
		case .retry(_, let rescus, let attempt, _):
			log = "Connection Attempt \(rescus).\(attempt)"
			break
		case .retriesFailed(let counter, let rescus, _):
			log = "Connection Failed \(counter).\(rescus)"
			break
		case .discconnected(let reason, let error):
			log = "Discconnected \(reason) \(error?.localizedDescription ?? "")"
			break
		}
	}
	
	
	func mqtt(client: MQTTClient, unhandledMessage: MQTTMessage) {
		DispatchQueue.main.async {
			self.delegate?.on(log: "Unhandled \(unhandledMessage)")
		}
	}
	
	func mqtt(client: MQTTClient, recreatedSubscriptions: [MQTTSubscription]) {
		DispatchQueue.main.async {
		}
	}
}
*/

