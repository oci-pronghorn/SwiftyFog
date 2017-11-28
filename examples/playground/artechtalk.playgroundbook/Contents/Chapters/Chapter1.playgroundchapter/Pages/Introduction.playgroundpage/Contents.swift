//: ## SwiftyFog & Foglight
//:
//: Using MQTT, we are sending a message to the **live view**.

import PlaygroundSupport

let metrics = MQTTMetrics()
metrics.debugOut = {print("- \($0)")}
metrics.doPrintSendPackets = true
metrics.doPrintReceivePackets = true
metrics.doPrintUnhandledPackets = true
metrics.doPrintIdRetains = true
metrics.doPrintWireData = true

let contentClient = PlaygroundMQTTClient(metrics: metrics)
contentClient.publish(MQTTMessage(topic: "hello", payload: "Hello World!".data(using: .utf8)!), completion: nil)

