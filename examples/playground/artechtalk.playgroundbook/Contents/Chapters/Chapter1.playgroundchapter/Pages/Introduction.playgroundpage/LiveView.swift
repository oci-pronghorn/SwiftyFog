/*
import PlaygroundSupport

let viewController = FoggyViewController()
PlaygroundPage.current.liveView = viewController
PlaygroundPage.current.needsIndefiniteExecution = true

let router = MQTTRouter()

class PlaygroundMQTTConnection: MQTTRouterDelegate {
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
/*
 extension PlaygroundMQTTConnection: PlaygroundLiveViewMessageHandler {
 // use the factory to move messages in/out of router
 }

 extension PlaygroundMQTTConnection: PlaygroundRemoteLiveViewProxyDelegate {
 // use the factory to move messages in/out of router
 }
*/

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

*/
