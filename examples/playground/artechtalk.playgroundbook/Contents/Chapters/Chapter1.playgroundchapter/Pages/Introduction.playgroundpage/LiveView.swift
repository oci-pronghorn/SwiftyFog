import UIKit
import PlaygroundSupport

let page = PlaygroundPage.current
page.needsIndefiniteExecution = true

public class MyViewController: UIViewController {
	var metrics = MQTTMetrics()
	var mqtt: PlaygroundMQTTClient!
	var subscription: MQTTBroadcaster!
	var testLabel: UILabel!
	
	override public func viewDidLoad() {
		super.viewDidLoad()
		
		self.testLabel = UILabel(frame: CGRect(x: 20, y: 20, width: 400, height: 80))
		self.testLabel.text = "Nothing"
		self.testLabel.numberOfLines = 0
		self.testLabel.lineBreakMode = .byCharWrapping
		self.view.addSubview(testLabel)
		
		metrics.debugOut = { [weak self] in
			print($0)
		}
		metrics.doPrintSendPackets = true
		metrics.doPrintReceivePackets = true
		metrics.doPrintUnhandledPackets = true
		metrics.doPrintIdRetains = true
		metrics.doPrintWireData = true
		
		mqtt = PlaygroundMQTTClient(metrics: metrics)
		
		subscription = mqtt.broadcast(to: self, topics: [
		 	("hello", .atMostOnce, MyViewController.receive)
		])
	}
	
	func receive(_ msg: MQTTMessage) {
		self.testLabel.text = "!\(msg.payload)"
	}
}

extension MyViewController: PlaygroundLiveViewMessageHandler {
	public func liveViewMessageConnectionOpened() {
		//self.testLabel.text = "Open"
	}
	
	public func liveViewMessageConnectionClosed() {
		//self.testLabel.text = "Close"
	}
	
	public func receive(_ value: PlaygroundValue) {
		self.mqtt.receive(value)
	}
}

let viewController = MyViewController()
/*
let viewController = FoggyViewController()
page.liveView = viewController
*/
page.liveView = viewController

