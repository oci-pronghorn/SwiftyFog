import PlaygroundSupport

public class PlaygroundMQTTClient : MQTTRouterDelegate {
	let router = MQTTRouter()
	let factory = MQTTPacketFactory()
	
	public init() {
		print("Initialized MQTT")
		router.delegate = self
	}

	public func mqtt(send packet: MQTTPacket, completion: @escaping (Bool)->()) {
		print("Routing: \(packet)")
		//Going from CONTENTS -> LIVEVIEW
		let page = PlaygroundPage.current
		if let proxy = page.liveView as? PlaygroundRemoteLiveViewProxy {
			let data = factory.marshal(packet)
			let payload : PlaygroundValue = .data(data)
			proxy.send(payload)
		}
	}
	
	public func mqtt(unhandledMessage: MQTTMessage) {
		print("Unhandled \(unhandledMessage)")
	}
}

/* MQTT Bridge Handler */
extension PlaygroundMQTTClient: MQTTBridge {
	public func createBridge(subPath: String) -> MQTTBridge {
		return router.createBridge(subPath: subPath)
	}
	
	public func publish(_ pubMsg: MQTTMessage, completion: ((Bool)->())?) {
		router.publish(pubMsg, completion: completion)
	}
	
	public func subscribe(topics: [(String, MQTTQoS)], acknowledged: SubscriptionAcknowledged?) -> MQTTSubscription {
		return router.subscribe(topics: topics, acknowledged: acknowledged)
	}
	
	public func register(topic: String, action: @escaping (MQTTMessage)->()) -> MQTTRegistration {
		return router.register(topic: topic, action: action)
	}
}

/* Playground Message Handler */
extension PlaygroundMQTTClient : PlaygroundLiveViewMessageHandler {
	public func liveViewMessageConnectionOpened() {
		print("opened live messaging")
	}
	
	public func liveViewMessageConnectionClosed() {
		print("closed live messaging")
	}
	
	public func receive(_ message: PlaygroundValue) {
		print("received playground value")
		if case .data ( let data ) = message {
			if case .success(let packet) = factory.unmarshal(data) {
				router.dispatch(packet: packet)
			}
		}
	}
}
