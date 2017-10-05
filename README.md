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

## Examples

The iOS example is written to work with the FogLight Java application, also in the examples directory.
The Mac example demonstrates similar concepts for the desktop. 
The AR example demonstrates integration of ARKit and FogLight/SwiftyFog.

## Requirements

## Author

dsjove, giovanninid@objectcomputing.com
tobischw, schweigert@objectcomputing.com (MacOS integration/AR demo)

## License

SwiftyFog is available under the MIT license. See the LICENSE file for more info.
