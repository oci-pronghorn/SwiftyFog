import PlaygroundSupport

public class PlaygroundMQTTClient : MQTTRouterDelegate {
	let metrics: MQTTMetrics?
	let router: MQTTRouter
	let factory: MQTTPacketFactory
	
	public init(metrics: MQTTMetrics? = nil) {
		metrics?.debug("Initialize MQTT")
		self.metrics = metrics
		self.router = MQTTRouter(metrics: metrics)
		self.factory = MQTTPacketFactory(metrics: metrics)
		router.delegate = self
	}

	public func mqtt(send packet: MQTTPacket, completion: @escaping (Bool)->()) {
		metrics?.debug("Routing: \(packet)")
		let page = PlaygroundPage.current
		//Going from CONTENTS -> LIVEVIEW
		if let proxy = page.liveView as? PlaygroundRemoteLiveViewProxy {
			let data = factory.marshal(packet)
			let payload : PlaygroundValue = .data(data)
			proxy.send(payload)
		}
		else {
			metrics?.debug("No Live View to send to")
		}
	}
	
	public func mqtt(unhandledMessage: MQTTMessage) {
		metrics?.debug("Unhandled \(unhandledMessage)")
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

/* PlaygroundLiveViewMessageHandler */
extension PlaygroundMQTTClient {
	public func receive(_ value: PlaygroundValue) {
		metrics?.debug("Received Playground Value: \(value)")
		if case .data ( let data ) = value {
			if case .success(let packet) = factory.unmarshal(data) {
				router.dispatch(packet: packet)
			}
			else {
				metrics?.debug("Failed to unmarshal packet")
			}
		}
		else {
			metrics?.debug("Received Playground Value NOT DATA")
		}
	}
}
