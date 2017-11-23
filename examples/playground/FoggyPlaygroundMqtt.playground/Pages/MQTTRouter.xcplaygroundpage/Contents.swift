//: [Previous](@previous)

import Foundation
import SwiftyFog_iOS

let router = MQTTRouter()

class Direct: MQTTRouterDelegate {
	func mqtt(send packet: MQTTPacket, completion: @escaping (Bool)->()) {
		print("Routing to self\(packet)")
		router.dispatch(packet: packet)
	}
	func mqtt(unhandledMessage: MQTTMessage) {
		print("Unhandled \(unhandledMessage)")
	}
}

class MasrshaledDirect: MQTTRouterDelegate {
	let factory = MQTTPacketFactory()
	func mqtt(send packet: MQTTPacket, completion: @escaping (Bool)->()) {
		// TODO marshal and unmarshal using factory
		router.dispatch(packet: packet)
	}
	func mqtt(unhandledMessage: MQTTMessage) {
		print("Unhandled \(unhandledMessage)")
	}
}

let connect = Direct()
router.delegate = connect

class Business {
	func receive(_ msg: MQTTMessage) {
		print("Received \(msg)")
	}
}

let business = Business()
var subscription: MQTTBroadcaster? = router.broadcast(to: business, topics: [("hello", .atMostOnce, Business.receive)])
router.publish(MQTTMessage(topic: "hello"), completion: nil)
subscription = nil
