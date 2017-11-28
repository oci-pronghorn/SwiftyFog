//: ## SwiftyFog & Foglight
//:
//: Using MQTT, we are sending a message to the **live view**.

import PlaygroundSupport

let contentClient = PlaygroundMQTTClient()
contentClient.publish(MQTTMessage(topic: "hello", payload: "Hello World!".data(using: .utf8)!), completion: nil)
