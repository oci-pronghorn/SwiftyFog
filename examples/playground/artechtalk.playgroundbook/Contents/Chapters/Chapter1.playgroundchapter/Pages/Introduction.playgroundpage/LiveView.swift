import UIKit
import PlaygroundSupport

let container = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
var testLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
testLabel.center = CGPoint(x: 160, y: 284)
testLabel.text = "Nothing"
container.addSubview(testLabel)

PlaygroundPage.current.liveView = container
PlaygroundPage.current.needsIndefiniteExecution = true

let metrics = MQTTMetrics()
metrics.debugOut = {
	print("- \($0)")
	testLabel.text = "\($0)"
}
metrics.doPrintSendPackets = true
metrics.doPrintReceivePackets = true
metrics.doPrintUnhandledPackets = true
metrics.doPrintIdRetains = true
metrics.doPrintWireData = true

let liveViewClient = PlaygroundMQTTClient(metrics: metrics)

class Business {
	func receive(_ msg: MQTTMessage) {
		testLabel.text = "Data: \(msg)"
	}
}

let business = Business()

var subscription: MQTTBroadcaster? = liveViewClient.broadcast(to: business, topics: [
  ("hello", .atMostOnce, Business.receive)
])

/*
let viewController = FoggyViewController()
PlaygroundPage.current.liveView = viewController
*/
