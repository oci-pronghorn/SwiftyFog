# SwiftyFog

SwiftyFog is a specification compliant robust and performant MQTT client implementation. It is entirely written in Swift with the following design considerations.
* Idiomatic Swift
* Unhappy-path driven design; every failure point captured and propagated to the business layer
* Optional behaviors in MQTT specification exposed
* Resource conscious
* No global state
* Incoming packet wild card distribution
* Additional Mobile and MVC friendly APIs
* Support for multiple MQTT connections
* Only dependent on Swift Foundation
* Non-trivial example demonstrating usage and patterns

There are couple remaining TODOs...
* Many More Unit Tests
* Better packet retry configuration
* File persisted packets for clean session false and relaunch of application
* Not "fighting the framework" in the Stream/RunLoop wrappers
* Continue to improve Metrics information
* Complete Linux/Raspberry Pi build
* Enable MQTTMultiClientAppController on all platforms

## License
SwiftyFog is available under the MIT license. See the LICENSE file for more info.

## Author
dsjove, dsjove@gmail.com

## Helpful Links and Commands

Raspberry Pi OSs
https://www.raspberrypi.org/downloads/

Install Swift on Raspberry Pi
http://swift-arm.com
curl -s https://packagecloud.io/install/repositories/swift-arm/debian/script.deb.sh | sudo bash

sudo apt-get install swift-4.1-RPi23-RaspbianStretch
or
sudo apt-get install swift-4.1-RPi23-Ubuntu1604

Install Mosquitto Client
sudo apt-get install mosquitto-clients

Install Mosquitto Server
sudo apt-get install mosquitto

Zeroconf Broadcast MQTT Broker On Raspberry Pi
sudo apt-get install avahi-daemon avahi-discover avahi-utils libnss-mdns mdns-scan
hn=`hostname`;cn=$(echo "$hn" | cut -f 1 -d '.');avahi-publish -s ${cn}.local _mqtt._tcp 1883

Zeroconf Broadcast MQTT Broker On Mac
hn=`hostname`;cn=$(echo "$hn" | cut -f 1 -d '.');dns-sd -R ${cn} _mqtt._tcp local 1883
