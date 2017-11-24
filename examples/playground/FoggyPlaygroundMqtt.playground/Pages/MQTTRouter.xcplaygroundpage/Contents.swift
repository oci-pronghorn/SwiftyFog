//: [Previous](@previous)

import Foundation
import SwiftyFog_iOS

let router = MQTTRouter()

class Direct: MQTTRouterDelegate {
	func mqtt(send packet: MQTTPacket, completion: @escaping (Bool)->()) {
		print("Routing: \(packet)")
		router.dispatch(packet: packet)
	}
	func mqtt(unhandledMessage: MQTTMessage) {
		print("Unhandled \(unhandledMessage)")
	}
}

class MasrshalledDirect: MQTTRouterDelegate {
	let factory = MQTTPacketFactory()
	func mqtt(send packet: MQTTPacket, completion: @escaping (Bool)->()) {
		print("Routing: \(packet)")
		var data = Data()
		factory.send(packet) { wrapper in
			wrapper { ptr, l in
				data = Data(bytes: ptr, count: l)
				return l
			}
		}
		var cursor = 0
		var result = UnmarshalState.failedReadHeader
		data.withUnsafeBytes { (u8Ptr: UnsafePointer<UInt8>) in
			result = factory.receive { ptr, l in
				let pos = u8Ptr.advanced(by: cursor)
				memcpy(ptr, pos, l)
				cursor += l
				return l
			}
		}
	
		if case .success(let packet) = result {
			router.dispatch(packet: packet)
		}
	}
	func mqtt(unhandledMessage: MQTTMessage) {
		print("Unhandled: \(unhandledMessage)")
	}
}

let connect = MasrshalledDirect()
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
