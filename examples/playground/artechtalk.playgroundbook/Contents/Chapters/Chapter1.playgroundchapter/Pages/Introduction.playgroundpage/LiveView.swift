import PlaygroundSupport
import EmbeddFoggyAR

let mqtt = PlaygroundMQTTClient(nil)

let viewController = FoggyViewController()
viewController.mqtt = mqtt
PlaygroundPage.current.liveView = viewController
PlaygroundPage.current.needsIndefiniteExecution = true
