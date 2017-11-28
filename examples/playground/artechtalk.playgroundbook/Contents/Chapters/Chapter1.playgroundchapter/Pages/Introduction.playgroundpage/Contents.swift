//: ## SwiftyFog & AR Kit
//:
//: Using MQTT, we are sending a message to the **live view**.
//: The plyground is the broker that sends the MQTT packets between the pages' processes.

import PlaygroundSupport

//#-hidden-code
let page = PlaygroundPage.current
page.needsIndefiniteExecution = true

let metrics = MQTTMetrics()
metrics.debugOut = {print("- \($0)")}
metrics.doPrintSendPackets = true
metrics.doPrintReceivePackets = true
metrics.doPrintUnhandledPackets = true
metrics.doPrintIdRetains = true
metrics.doPrintWireData = true
let mqtt = PlaygroundMQTTClient(contentViewMessageHandler: page.liveView as! PlaygroundRemoteLiveViewProxy, metrics: metrics)
//#-end-hidden-code

mqtt.publish(
	MQTTMessage(topic: "hello", payload: /*#-editable-code*/"<#Hello World!#>"/*#-end-editable-code*/.data(using: .utf8)!), completion: nil)

