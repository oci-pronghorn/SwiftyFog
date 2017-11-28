import PlaygroundSupport

public class PlaygroundMQTTClient {
	private let metrics: MQTTMetrics?
	private let router: MQTTRouter
	private let factory: MQTTPacketFactory
	private weak var liveViewMessageHandler: PlaygroundLiveViewMessageHandler!
	private weak var contentViewMessageHandler: PlaygroundRemoteLiveViewProxy!
	
	public convenience init(metrics: MQTTMetrics? = nil) {
		self.init(liveViewMessageHandler: nil, contentViewMessageHandler: nil, metrics: metrics)
	}
	
	public convenience init(liveViewMessageHandler: PlaygroundLiveViewMessageHandler, metrics: MQTTMetrics? = nil) {
		self.init(liveViewMessageHandler: liveViewMessageHandler, contentViewMessageHandler: nil, metrics: metrics)
	}
	
	public convenience init(contentViewMessageHandler: PlaygroundRemoteLiveViewProxy, metrics: MQTTMetrics? = nil) {
		self.init(liveViewMessageHandler: nil, contentViewMessageHandler: contentViewMessageHandler, metrics: metrics)
		contentViewMessageHandler.delegate = self
	}
	
	private init(
		liveViewMessageHandler: PlaygroundLiveViewMessageHandler?,
		contentViewMessageHandler: PlaygroundRemoteLiveViewProxy?,
		metrics: MQTTMetrics? = nil) {

		self.liveViewMessageHandler = liveViewMessageHandler
		self.contentViewMessageHandler = contentViewMessageHandler
		self.metrics = metrics
		self.router = MQTTRouter(metrics: metrics)
		self.factory = MQTTPacketFactory(metrics: metrics)
		
		router.delegate = self
	}
}

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

extension PlaygroundMQTTClient : MQTTRouterDelegate {
	// Takes an MQTT message and sends it to the Playground as if it was a broker
	public func mqtt(send packet: MQTTPacket, completion: @escaping (Bool)->()) {
		let data = factory.marshal(packet)
		let payload : PlaygroundValue = .data(data)
		// * Sends a message from Content to Live View
		if let contentViewMessageHandler = contentViewMessageHandler {
			contentViewMessageHandler.send(payload)
		}
		// * Sends a message from Live View to Content
		else if let liveViewMessageHandler = liveViewMessageHandler {
			liveViewMessageHandler.send(payload)
		}
		// * Sends directly to self
		else if case .success(let packet) = factory.unmarshal(data) {
			router.dispatch(packet: packet)
		}
		else {
			metrics?.debug("Failed to unmarshal packet")
		}
	}
	
	public func mqtt(unhandledMessage: MQTTMessage) {
	}
}

extension PlaygroundMQTTClient: PlaygroundRemoteLiveViewProxyDelegate {
	// * Receives a message from LiveView and delivered to ContentView
	public func remoteLiveViewProxy(_ remoteLiveViewProxy: PlaygroundRemoteLiveViewProxy, received message: PlaygroundValue) {
		receive(playgroundValue: message)
	}
	
	public func remoteLiveViewProxyConnectionClosed(_ remoteLiveViewProxy: PlaygroundRemoteLiveViewProxy) {
		metrics?.debug("Live View closed connection to client")
	}
}

extension PlaygroundMQTTClient {
	// * Receives a message from ContentView and deleivered to LiveView
	// * Manually call from PlaygroundLiveViewMessageHandler in the LiveView
	public func receive(playgroundValue value: PlaygroundValue) {
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
