//: [Previous](@previous)

import Foundation

import PlaygroundSupport
import SwiftyFog_iOS

let router = MQTTRouter()

class ConnectivityTissue: MQTTRouterDelegate {
	func mqtt(send packet: MQTTPacket, completion: @escaping (Bool)->()) {
		router.dispatch(packet: packet)
	}

	func mqtt(unhandledMessage: MQTTMessage) {
		print("Unhandled \(unhandledMessage)")
	}
}

let connect = ConnectivityTissue()
router.delegate = connect

class Business {
	func receive(_ msg: MQTTMessage) {
		print("Received \(msg)")
	}
}

let business = Business()
var subscription = router.broadcast(to: business, topics: [("hello", .atMostOnce, Business.receive)])
router.publish(MQTTMessage(topic: "hello"), completion: nil)

