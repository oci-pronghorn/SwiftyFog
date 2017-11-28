import UIKit
import PlaygroundSupport

let container = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
var testLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
testLabel.center = CGPoint(x: 160, y: 284)
testLabel.text = "Nothing"
container.addSubview(testLabel)

PlaygroundPage.current.liveView = container
PlaygroundPage.current.needsIndefiniteExecution = true

let liveViewClient = PlaygroundMQTTClient()

class Business {
	func receive(_ msg: MQTTMessage) {
		testLabel.text = "Data: \(msg.payload)"
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
