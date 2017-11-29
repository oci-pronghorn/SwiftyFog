import UIKit
import PlaygroundSupport

let page = PlaygroundPage.current
page.needsIndefiniteExecution = true

var metrics = MQTTMetrics()
metrics.debugOut = {
	print($0)
}
metrics.doPrintSendPackets = true
metrics.doPrintReceivePackets = true
metrics.doPrintUnhandledPackets = true
metrics.doPrintIdRetains = true
metrics.doPrintWireData = true

public class MyViewController: UIViewController {
	var subscription: MQTTBroadcaster!
	var testLabel: UILabel!
	
	var mqtt: MQTTBridge! {
		didSet {
			subscription = mqtt.broadcast(to: self, topics: [
				("hello", .atMostOnce, MyViewController.receive)
			])
		}
	}
	
	override public func viewDidLoad() {
		super.viewDidLoad()
		self.testLabel = UILabel(frame: CGRect(x: 20, y: 20, width: 400, height: 80))
		self.testLabel.text = "Nothing"
		self.testLabel.numberOfLines = 0
		self.testLabel.lineBreakMode = .byCharWrapping
		self.view.addSubview(testLabel)
	}
	
	func receive(_ msg: MQTTMessage) {
		self.testLabel.text = "!\(msg.payload)"
	}
	
	public func liveViewMessageConnectionOpened() {
	}
	
	public func liveViewMessageConnectionClosed() {
	}
}

// Wire up mqtt to playground per message received.
// There has got to be a better way.
extension MyViewController: PlaygroundLiveViewMessageHandler {
	public func receive(_ value: PlaygroundValue) {
		(self.mqtt as! PlaygroundMQTTClient).dispatch(playgroundValue: value)
	}
}
extension FoggyViewController: PlaygroundLiveViewMessageHandler {
	public func receive(_ value: PlaygroundValue) {
		(self.mqtt as! PlaygroundMQTTClient).dispatch(playgroundValue: value)
	}
}

//let viewController = MyViewController()
let viewController = FoggyViewController()

let mqtt = PlaygroundMQTTClient(liveViewMessageHandler: viewController, metrics: metrics)
viewController.mqtt = mqtt
page.liveView = viewController

