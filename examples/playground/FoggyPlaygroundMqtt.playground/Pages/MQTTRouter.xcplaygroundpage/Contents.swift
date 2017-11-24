//: [Previous](@previous)

import Foundation
import SwiftyFog_iOS

let router = MQTTRouter()

class Direct: MQTTRouterDelegate {
	let factory = MQTTPacketFactory()
	func mqtt(send packet: MQTTPacket, completion: @escaping (Bool)->()) {
		print("Routing: \(packet)")
		let data = factory.marshal(packet)
		let result = factory.unmarshal(data)
		if case .success(let packet) = result {
			router.dispatch(packet: packet)
		}
	}
	func mqtt(unhandledMessage: MQTTMessage) {
		print("Unhandled \(unhandledMessage)")
	}
}

let connect = Direct()
router.delegate = connect

class Business {
	func receive(_ msg: MQTTMessage) {
		print("Received: \(msg)")
	}
}

let business = Business()
var subscription: MQTTBroadcaster? = router.broadcast(to: business, topics: [("hello", .atMostOnce, Business.receive)])
router.publish(MQTTMessage(topic: "hello", payload: "something".data(using: .utf8)!), completion: nil)
subscription = nil
