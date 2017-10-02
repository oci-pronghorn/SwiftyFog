# SwiftyFog

SwiftyFog is a specification compliant robust and performant MQTT client implementation. It is entirely written in Swift with the following design considerations.
* Idiomatic Swift
* Unhappy-path driven design; every failure point captured and propagated to the business layer
* Mobile and MVC friendly interfaces
* Optional behaviors in specification exposed
* Resource conscious
* Non-trivial example demonstrating usage and patterns

There are couple remaining TODOs.
* Better packet retry configuration
* File persisted packets for clean session false and relaunch of application
* Not fighting the framework in the iOS Stream wrapper
* Continue to improve Metrics information
* Rewrite 4 year old Obj-C code in example custom controls
* SwiftPackage Manager

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.
There is a java example built on FogLight technology to be the smart device on the other side of the MQTT broker.

## Requirements

## Author

dsjove, giovanninid@objectcomputing.com

## License

SwiftyFog is available under the MIT license. See the LICENSE file for more info.
