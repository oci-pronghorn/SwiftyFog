# SwiftyFog

SwiftyFog is a specification compliant robust and performant MQTT client implementation. It is entirely written in Swift with the following design principles
* Idiomatic Swift
* Unhappy-path driven design; every failure point captured and propagated to the business layer.
* Mobile and MVC friendly interfaces
* Optional behaviors in specification exposed
* Resource conscious.
* Non-trivial example

There are couple remaining TODOs.
* Better packet retry configuration
* File persisted packets for clean session false and relaunch of application
* MacOS build and example
* Not fighting the framework in the iOS Stream wrapper

[![CI Status](http://img.shields.io/travis/dsjove/SwiftyFog.svg?style=flat)](https://travis-ci.org/dsjove/SwiftyFog)
[![Version](https://img.shields.io/cocoapods/v/SwiftyFog.svg?style=flat)](http://cocoapods.org/pods/SwiftyFog)
[![License](https://img.shields.io/cocoapods/l/SwiftyFog.svg?style=flat)](http://cocoapods.org/pods/SwiftyFog)
[![Platform](https://img.shields.io/cocoapods/p/SwiftyFog.svg?style=flat)](http://cocoapods.org/pods/SwiftyFog)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.
There is a java example built on FogLight technology to be the smart device on the other side of the MQTT broker.

## Requirements

## Installation

SwiftyFog is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "SwiftyFog"
```

## Author

dsjove, giovanninid@objectcomputing.com

## License

SwiftyFog is available under the MIT license. See the LICENSE file for more info.
